import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/dart_telegram_bot.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/telegram_entities.dart';

/// An interceptor that logs API errors and sends them to a specified Telegram chat.
/// This interceptor automatically formats the error messages using MarkdownV2 rules
/// and supports additional features like including request headers and ignoring specific status codes.
class TelegramErrorInterceptor extends Interceptor {
  /// Telegram Bot Token (required for authentication)
  final String botToken;

  /// Telegram Chat ID (required for sending messages)
  final int chatId;

  /// HTTP status codes that should be ignored when sending error messages
  final List<int> ignoreStatusCodes;

  /// Whether to include request headers in the error message
  final bool includeHeaders;

  /// Singleton instance for global access
  static TelegramErrorInterceptor? _instance;

  /// Factory constructor for creating or accessing a singleton instance
  factory TelegramErrorInterceptor({
    required String botToken,
    required int chatId,
    required List<int> ignoreStatusCodes,
    required bool includeHeaders,
  }) {
    _instance ??= TelegramErrorInterceptor._internal(
      botToken,
      chatId,
      ignoreStatusCodes,
      includeHeaders,
    );
    return _instance!;
  }

  /// Private named constructor to initialize class properties
  TelegramErrorInterceptor._internal(
    this.botToken,
    this.chatId,
    this.ignoreStatusCodes,
    this.includeHeaders,
  );

  /// Sends the formatted error message to the specified Telegram chat
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

  /// Handles successful responses, checks for non-success status codes,
  /// and sends the response details to Telegram if applicable.
  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    // Only log responses with non-success status codes that are not ignored
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

      // Collect request headers if enabled
      String requestHeaders = '';
      if (includeHeaders) {
        response.requestOptions.headers.forEach((key, value) {
          requestHeaders += "${key}: ${value.toString()}\n";
        });
      }

      // Format the response message
      String responseMessage = ""
          "\\#️⃣TAGS: ${escapeMarkdown('#$method, #STATUSCODE_$statusCode')}\n\n"
          "🔴 *Bad Response Detected*\n\n"
          "$deviceSticker *Device:* ${escapeMarkdown(device)}\n\n"
          "🌐 *URL:* `${escapeMarkdown(url)}`\n\n"
          "${includeHeaders ? "📥 *Request Headers:*\n${escapeMarkdown(requestHeaders)}\n\n" : ''}"
          "📝 *Request Data:* ${escapeMarkdown(requestMessage)}\n\n"
          "📄 *Response Data:* ${escapeMarkdown(responseData)}"
          "";

      // Send the formatted response to Telegram
      await sendErrorToTelegram(responseMessage);
    }

    // Pass the response to the next handler
    handler.next(response);
  }

  /// Handles Dio request errors, formats the message, and sends it to Telegram
  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    String errorMessage;
    String requestHeaders = '';

    // Extract essential request and device information
    String url = err.requestOptions.uri.toString();
    String errMessage = err.message ?? 'Unknown Error';
    String deviceSticker = getDeviceSticker();
    String device = await getDevice();

    // Collect request headers if enabled
    if (includeHeaders) {
      err.requestOptions.headers.forEach((key, value) {
        requestHeaders += "${key}: ${value.toString()}\n";
      });
    }

    // Format error message
    errorMessage = ""
        "\\#️⃣TAGS: ${escapeMarkdown("#${err.requestOptions.method}, #STATUSCODE_${err.response?.statusCode.toString() ?? 'Unknown'}, #${err.type.name}")}\n\n"
        "🔴 *Error Occurred*\n\n"
        "$deviceSticker *Device:* ${escapeMarkdown(device)}\n\n"
        "💬 *Message:* ${escapeMarkdown(errMessage)}\n\n"
        "🌐 *URL:* `${escapeMarkdown(url)}`\n\n"
        "${includeHeaders ? "📥 *Request Headers:*\n${escapeMarkdown(requestHeaders)}\n\n" : ''}"
        "📝 *Request Data:* ${escapeMarkdown(err.requestOptions.data?.toString() ?? 'No request data')}\n\n"
        "📄 *Response Data:* ${escapeMarkdown(err.response?.data?.toString() ?? 'No response data')}"
        "";

    // Send the error message to Telegram and pass the error to the next handler
    await sendErrorToTelegram(errorMessage);
    handler.next(err);
  }

  /// Escapes special characters for Telegram MarkdownV2 formatting
  /// Escapes special characters for Telegram MarkdownV2.
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

  /// Retrieves device information based on the platform
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

  /// Provides a platform-specific emoji sticker for easier device identification
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
