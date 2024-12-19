import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/dart_telegram_bot.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/telegram_entities.dart';

class TelegramErrorInterceptor extends Interceptor {
  /// Telegram Bot Token
  final String botToken;

  /// Telegram Chat ID
  final int chatId;

  final List<int> ignoreStatusCodes;

  /// Include headers in the error message
  final bool includeHeaders;

  /// Singleton instance
  static TelegramErrorInterceptor? _instance;

  /// Singleton factory
  factory TelegramErrorInterceptor({
    required String botToken,
    required int chatId,
    required List<int> ignoreStatusCodes,
    required bool includeHeaders,
  }) {
    _instance ??= TelegramErrorInterceptor._internal(
        botToken, chatId, ignoreStatusCodes, includeHeaders);
    return _instance!;
  }

  /// Private constructor
  TelegramErrorInterceptor._internal(
    this.botToken,
    this.chatId,
    this.ignoreStatusCodes,
    this.includeHeaders,
  );

  /// Send error message to Telegram function
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

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    String errorMessage;
    String sticker;
    String requestHeaders = '';

    /// Get the request URL, status code, status message, and error message
    String url = escapeMarkdown(err.requestOptions.uri.toString());
    String errMessage = escapeMarkdown(err.message ?? 'Unknown Error');
    String deviceSticker = getDeviceSticker();
    String device = await getDevice();

    if (includeHeaders) {
      /// Get the request headers
      err.requestOptions.headers.forEach((key, value) {
        requestHeaders += "$key: $value\n";
      });
    }

    /// Define sticker and create an error message with stickers for each line
    switch (err.type) {
      case DioExceptionType.sendTimeout:
        sticker = '⏰';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Send Timeout Error*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.receiveTimeout:
        sticker = '⏳';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Receive Timeout Error*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.cancel:
        sticker = '🚫';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Request Cancelled*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.connectionTimeout:
        sticker = '🔗';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Connection Timeout*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.badCertificate:
        sticker = '📜';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Bad Certificate Error*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.connectionError:
        sticker = '🔌';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Connection Error*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;
      case DioExceptionType.badResponse:
        sticker = '🔌';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Bad Response*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "🔴 *Method:* `${err.requestOptions.method}`\n"
            "⚠️ *Status Code:* `${err.response?.statusCode}`\n"
            "🌐 *URL:* `$url`\n"
            "${includeHeaders ? "📥 *Request Headers:*\n$requestHeaders\n" : ''}"
            "📝 *Request Data:* ${err.requestOptions.data?.toString() ?? 'No request data'}\n"
            "📄 *Response Data:* ${err.response?.data?.toString() ?? 'No response data'}";
        break;

      default:
        sticker = '🤷🏻‍♀️🤷🏻‍♂️';
        errorMessage =
            "#️⃣TAGS: \\#${err.requestOptions.method}, \\#${err.response?.statusCode}, \\#${err.type.name}\n"
            "$sticker *Unknown Error*\n\n"
            "$deviceSticker *Device:* \\#$device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;
    }

    /// Send error message with sticker to Telegram
    sendErrorToTelegram(errorMessage);

    /// Call the next error handler
    handler.next(err);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    if (((response.statusCode ?? 0) < 200 ||
            (response.statusCode ?? 0) >= 300) &&
        !ignoreStatusCodes.contains(response.statusCode)) {
      String sticker = '🔴';
      String method = escapeMarkdown(response.requestOptions.method);
      String url = escapeMarkdown(response.requestOptions.uri.toString());
      String statusCode = escapeMarkdown(response.statusCode.toString());
      String requestMessage = escapeMarkdown(
          response.requestOptions.data?.toString() ?? 'No request data');
      String responseData =
          escapeMarkdown(response.data?.toString() ?? 'No response data');
      String deviceSticker = getDeviceSticker();
      String device = await getDevice();
      String requestHeaders = '';

      if (includeHeaders) {
        response.requestOptions.headers.forEach((key, value) {
          requestHeaders += "$key: $value\n";
        });
      }

      String errorMessage = "#️⃣TAGS: \\#$method, \\#$statusCode\n"
          "$sticker *Bad Response*\n\n"
          "$deviceSticker *Device:* \\#$device\n"
          "🌐 *URL:* `$url`\n"
          "${includeHeaders ? "📥 *Request Headers:*\n$requestHeaders\n" : ''}"
          "📝 *Request Data:* $requestMessage\n"
          "📄 *Response Data:* $responseData";
      sendErrorToTelegram(errorMessage);
    }
    super.onResponse(response, handler);
  }

  /// Escape MarkdownV2 special characters
  String escapeMarkdown(String text) {
    return text.replaceAllMapped(
        RegExp(r'([_*`$begin:math:display$$end:math:display${}()~>#+\-=|.!])'),
        (match) => '\\${match[0]}');
  }

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

  String getDeviceSticker() {
    String sticker = '🤷🏻‍♀️🤷🏻‍♂️';
    switch (Platform.operatingSystem) {
      case 'android':
        sticker = '📱';
        break;
      case 'ios':
        sticker = '🍏';
        break;
      case 'linux':
        sticker = '📟';
        break;
      case 'macos':
        sticker = '🖥';
        break;
      case 'windows':
        sticker = '💠';
        break;
    }
    return sticker;
  }
}
