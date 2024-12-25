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
  /// Requires the `slackWebhookUrl` to be set.
  Future<void> sendErrorToSlack(String errorMessage) async {
    if (slackWebhookUrl == null || errorMessage.isEmpty) return;

    final dio = Dio();
    try {
      await dio.post(
        slackWebhookUrl!,
        data: {"text": errorMessage}, // Slack expects plain text messages.
        options: Options(headers: {"Content-Type": "application/json"}),
      );
    } catch (e) {
      log('Failed to send error message to Slack: $e');
    }
  }

  /// Sends an error message to both Telegram and Slack.
  Future<void> sendErrorToBoth(String errorMessage) async {
    await sendErrorToTelegram(errorMessage);
    await sendErrorToSlack(errorMessage);
  }

  /// Handles successful HTTP responses.
  ///
  /// Logs and sends responses with non-success status codes to Telegram and Slack.
  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    if ((response.statusCode ?? 0) < 200 ||
        (response.statusCode ?? 0) >= 300 &&
            !ignoreStatusCodes.contains(response.statusCode)) {
      String method = response.requestOptions.method;
      String url = response.requestOptions.uri.toString();
      String statusCode = response.statusCode.toString();
      String requestMessage =
          response.requestOptions.data?.toString() ?? 'No request data';
      String responseData = response.data?.toString() ?? 'No response data';

      String deviceSticker = getDeviceSticker();
      String device = await getDevice();

      String requestHeaders = '';
      if (includeHeaders) {
        response.requestOptions.headers.forEach((key, value) {
          requestHeaders += "${key}: ${value.toString()}\n";
        });
      }

      String responseMessage = ""
          "\\#️⃣TAGS: ${escapeMarkdown('#$method, #STATUSCODE_$statusCode')}\n\n"
          "🔴 *Bad Response Detected*\n\n"
          "$deviceSticker *Device:* ${escapeMarkdown(device)}\n\n"
          "🌐 *URL:* `${escapeMarkdown(url)}`\n\n"
          "${includeHeaders ? "📥 *Request Headers:*\n${escapeMarkdown(requestHeaders)}\n\n" : ''}"
          "📝 *Request Data:* ${escapeMarkdown(requestMessage)}\n\n"
          "📄 *Response Data:* ${escapeMarkdown(responseData)}"
          "";

      await sendErrorToBoth(responseMessage);
    }
    handler.next(response);
  }

  /// Handles Dio request errors.
  ///
  /// Logs and sends error details to Telegram and Slack.
  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    String url = err.requestOptions.uri.toString();
    String errMessage = err.message ?? 'Unknown Error';
    String deviceSticker = getDeviceSticker();
    String device = await getDevice();

    String requestHeaders = '';
    if (includeHeaders) {
      err.requestOptions.headers.forEach((key, value) {
        requestHeaders += "${key}: ${value.toString()}\n";
      });
    }

    String errorMessage = ""
        "\\#️⃣TAGS: ${escapeMarkdown("#${err.requestOptions.method}, #STATUSCODE_${err.response?.statusCode.toString() ?? 'Unknown'}, #${err.type.name}")}\n\n"
        "🔴 *Error Occurred*\n\n"
        "$deviceSticker *Device:* ${escapeMarkdown(device)}\n\n"
        "💬 *Message:* ${escapeMarkdown(errMessage)}\n\n"
        "🌐 *URL:* `${escapeMarkdown(url)}`\n\n"
        "${includeHeaders ? "📥 *Request Headers:*\n${escapeMarkdown(requestHeaders)}\n\n" : ''}"
        "📝 *Request Data:* ${escapeMarkdown(err.requestOptions.data?.toString() ?? 'No request data')}\n\n"
        "📄 *Response Data:* ${escapeMarkdown(err.response?.data?.toString() ?? 'No response data')}"
        "";

    await sendErrorToBoth(errorMessage);
    handler.next(err);
  }

  /// Escapes special characters for Telegram MarkdownV2 formatting.
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
  Future<String> getDevice() async {
    String deviceInfo = 'Unknown Device';
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceInfo = 'Android ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceInfo = 'iOS ${iosInfo.utsname.machine}';
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfoPlugin.linuxInfo;
      deviceInfo = 'Linux ${linuxInfo.prettyName}';
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfoPlugin.macOsInfo;
      deviceInfo = 'macOS ${macInfo.model}';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfoPlugin.windowsInfo;
      deviceInfo = 'Windows ${windowsInfo.computerName}';
    }

    return deviceInfo;
  }

  /// Provides a platform-specific emoji sticker for easier device identification.
  String getDeviceSticker() {
    switch (Platform.operatingSystem) {
      case 'android':
        return '📱';
      case 'ios':
        return '🍏';
      case 'linux':
        return '📟';
      case 'macos':
        return '🖥';
      case 'windows':
        return '💠';
      default:
        return '🤷🏻‍♀️🤷🏻‍♂️';
    }
  }
}