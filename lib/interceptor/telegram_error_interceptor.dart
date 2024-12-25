import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/dart_telegram_bot.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/telegram_entities.dart';

/// An interceptor for logging and sending API errors to Telegram and Slack.
///
/// Features:
/// - Sends error and response details to Telegram using a bot.
/// - Optionally sends error messages to Slack via Webhook.
/// - Integrates with Dio to intercept HTTP requests and responses.
class TelegramErrorInterceptor extends Interceptor {
  /// The token of the Telegram bot that sends error messages.
  ///
  /// Obtain this token from Telegram's `BotFather`.
  final String botToken;

  /// The ID of the Telegram chat where error messages are sent.
  ///
  /// This can be a user, group, or channel ID.
  final int chatId;

  /// The list of HTTP status codes to ignore when sending error messages.
  ///
  /// Default: An empty list (no codes are ignored).
  final List<int> ignoreStatusCodes;

  /// Whether to include HTTP headers in the error messages.
  ///
  /// Default: `false`.
  final bool includeHeaders;

  /// The Slack Webhook URL for sending error messages to Slack.
  ///
  /// Optional. Set this to send error messages to Slack.
  final String? slackWebhookUrl;

  /// Singleton instance for the interceptor.
  static TelegramErrorInterceptor? _instance;

  /// Factory constructor to create or access the singleton instance.
  ///
  /// Example:
  /// ```dart
  /// final interceptor = TelegramErrorInterceptor(
  ///   botToken: 'YOUR_TELEGRAM_BOT_TOKEN',
  ///   chatId: 123456789,
  ///   ignoreStatusCodes: [400, 404],
  ///   includeHeaders: true,
  ///   slackWebhookUrl: 'YOUR_SLACK_WEBHOOK_URL', // Optional
  /// );
  /// ```
  factory TelegramErrorInterceptor({
    required String botToken,
    required int chatId,
    required List<int> ignoreStatusCodes,
    required bool includeHeaders,
    String? slackWebhookUrl,
  }) {
    _instance ??= TelegramErrorInterceptor._internal(
      botToken,
      chatId,
      ignoreStatusCodes,
      includeHeaders,
      slackWebhookUrl,
    );
    return _instance!;
  }

  /// Private constructor to initialize the interceptor.
  TelegramErrorInterceptor._internal(
    this.botToken,
    this.chatId,
    this.ignoreStatusCodes,
    this.includeHeaders,
    this.slackWebhookUrl,
  );

  /// Sends an error message to Telegram.
  ///
  /// The message is formatted using Telegram's MarkdownV2 syntax.
  /// Example:
  /// ```dart
  /// await sendErrorToTelegram("An error occurred!");
  /// ```
  Future<void> sendErrorToTelegram(String errorMessage) async {
    final bot = Bot(token: botToken);
    try {
      await bot.sendMessage(
        ChatID(chatId),
        errorMessage,
        parseMode: ParseMode.markdownV2,
      );
    } catch (e) {
      log('Failed to send error message to Telegram: $e');
    }
  }

  /// Sends an error message to Slack.
  ///
  /// The message is formatted using Slack's block format for better readability.
  /// Requires the `slackWebhookUrl` to be set.
  Future<void> sendErrorToSlack(
    String method,
    String statusCode,
    String url,
    String device,
    String requestHeaders,
    String requestData,
    String responseData,
  ) async {
    if (slackWebhookUrl == null) return;

    final dio = Dio();
    final slackMessage = {
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text":
                "*#️⃣ TAGS:* `${method.toUpperCase()}, STATUSCODE_$statusCode`"
          }
        },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":red_circle: *Bad Response Detected*"
          }
        },
        {
          "type": "section",
          "text": {"type": "mrkdwn", "text": ":iphone: *Device:* $device"}
        },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":globe_with_meridians: *URL:* <$url|$url>"
          }
        },
        if (includeHeaders)
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": ":inbox_tray: *Request Headers:* ```$requestHeaders```"
            }
          },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":pencil: *Request Data:* ```$requestData```"
          }
        },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": ":page_facing_up: *Response Data:* ```$responseData```"
          }
        }
      ]
    };

    try {
      await dio.post(
        slackWebhookUrl!,
        data: slackMessage,
        options: Options(headers: {"Content-Type": "application/json"}),
      );
    } catch (e) {
      log('Failed to send error message to Slack: $e');
    }
  }

  /// Sends an error message to both Telegram and Slack.
  ///
  /// Example:
  /// ```dart
  /// await sendErrorToBoth("Critical failure!");
  /// ```
  Future<void> sendErrorToBoth(
    String method,
    String statusCode,
    String url,
    String device,
    String requestHeaders,
    String requestData,
    String responseData,
  ) async {
    final errorMessage = formatTelegramMessage(method, statusCode, url, device,
        requestHeaders, requestData, responseData);
    await sendErrorToTelegram(errorMessage);
    await sendErrorToSlack(method, statusCode, url, device, requestHeaders,
        requestData, responseData);
  }

  /// Formats the error message for Telegram.
  String formatTelegramMessage(
    String method,
    String statusCode,
    String url,
    String device,
    String requestHeaders,
    String requestData,
    String responseData,
  ) {
    return ""
        "\\#️⃣TAGS: ${escapeMarkdown('#$method, #STATUSCODE_$statusCode')}\n\n"
        "🔴 *Bad Response Detected*\n\n"
        "📱 *Device:* ${escapeMarkdown(device)}\n\n"
        "🌐 *URL:* `${escapeMarkdown(url)}`\n\n"
        "${includeHeaders ? "📥 *Request Headers:*\n${escapeMarkdown(requestHeaders)}\n\n" : ''}"
        "📝 *Request Data:* ${escapeMarkdown(requestData)}\n\n"
        "📄 *Response Data:* ${escapeMarkdown(responseData)}";
  }

  /// Intercepts Dio responses to check for non-success status codes and log errors.
  ///
  /// This function processes HTTP responses and checks if the status code is outside
  /// the successful range (200-299) and not in the `ignoreStatusCodes` list.
  /// If such a response is detected, it logs the error and sends details to Telegram and Slack.
  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    // Check if the status code is not successful (outside the range of 200-299)
    // and the status code is not in the ignore list
    if ((response.statusCode ?? 0) < 200 ||
        (response.statusCode ?? 0) >= 300 &&
            !ignoreStatusCodes.contains(response.statusCode)) {
      // Extract HTTP method, URL, status code, and other response details
      String method = response.requestOptions.method;
      String url = response.requestOptions.uri.toString();
      String statusCode = response.statusCode.toString();
      String requestData =
          response.requestOptions.data?.toString() ?? 'No request data';
      String responseData = response.data?.toString() ?? 'No response data';

      // Get device information
      String device = await getDevice();

      // Prepare request headers if includeHeaders is enabled
      String requestHeaders = '';
      if (includeHeaders) {
        response.requestOptions.headers.forEach((key, value) {
          requestHeaders += "$key: $value\n";
        });
      }

      // Send error details to Telegram and Slack
      await sendErrorToBoth(
        method,
        statusCode,
        url,
        device,
        requestHeaders,
        requestData,
        responseData,
      );
    }

    // Call the next handler in the chain
    handler.next(response);
  }

  /// Handles Dio request errors.
  ///
  /// Logs and sends error details to Telegram and Slack.
  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    String method = err.requestOptions.method;
    String url = err.requestOptions.uri.toString();
    String statusCode = err.response?.statusCode.toString() ?? 'Unknown';
    String requestHeaders = '';
    if (includeHeaders) {
      err.requestOptions.headers.forEach((key, value) {
        requestHeaders += "$key: $value\n";
      });
    }
    String requestData =
        err.requestOptions.data?.toString() ?? 'No request data';
    String responseData = err.response?.data?.toString() ?? 'No response data';

    String device = await getDevice();

    await sendErrorToBoth(method, statusCode, url, device, requestHeaders,
        requestData, responseData);
    handler.next(err);
  }

  /// Escapes special characters for Telegram MarkdownV2 formatting.
  ///
  /// Ensures compatibility with Telegram's message format.
  String escapeMarkdown(String text) {
    final Map<String, String> replacements = {
      '_': '\\_',
      '*': '\\*',
      '[': '\\[',
      ']': '\\]',
      '(': '\\(',
      ')': '\\)',
      '~': '\\~',
      '`': '\\`',
      '>': '\\>',
      '#': '\\#',
      '+': '\\+',
      '-': '\\-',
      '=': '\\=',
      '|': '\\|',
      '{': '\\{',
      '}': '\\}',
      '.': '\\.',
      '!': '\\!',
    };

    replacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });
    return text;
  }

  /// Retrieves device information based on the platform.
  ///
  /// Returns details like device model and operating system.
  Future<String> getDevice() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return 'Android ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return 'iOS ${iosInfo.utsname.machine}';
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfoPlugin.linuxInfo;
      return 'Linux ${linuxInfo.prettyName}';
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfoPlugin.macOsInfo;
      return 'macOS ${macInfo.model}';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfoPlugin.windowsInfo;
      return 'Windows ${windowsInfo.computerName}';
    }
    return 'Unknown Device';
  }
}
