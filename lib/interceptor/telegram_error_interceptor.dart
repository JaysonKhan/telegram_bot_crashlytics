import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/dart_telegram_bot.dart';
import 'package:telegram_bot_crashlytics/dart_telegram_bot/telegram_entities.dart';

class TelegramErrorInterceptor extends Interceptor {
  /// Telegram Bot Token
  final String botToken;

  /// Telegram Chat ID
  final int chatId;

  /// Singleton instance
  static TelegramErrorInterceptor? _instance;

  /// Singleton factory
  factory TelegramErrorInterceptor({required String botToken, required int chatId}) {
    _instance ??= TelegramErrorInterceptor._internal(botToken, chatId);
    return _instance!;
  }

  /// Private constructor
  TelegramErrorInterceptor._internal(this.botToken, this.chatId);

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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage;
    String sticker;

    /// Get the request URL, status code, status message, and error message
    String url = escapeMarkdown(err.requestOptions.uri.toString());
    String errMessage = escapeMarkdown(err.message ?? 'Unknown Error');
    String deviceSticker = getDeviceSticker();
    String device = getDevice();

    /// Define sticker and create an error message with stickers for each line
    switch (err.type) {
      case DioExceptionType.sendTimeout:
        sticker = '⏰';
        errorMessage = "$sticker *Send Timeout Error*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.receiveTimeout:
        sticker = '⏳';
        errorMessage = "$sticker *Receive Timeout Error*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.cancel:
        sticker = '🚫';
        errorMessage = "$sticker *Request Cancelled*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.connectionTimeout:
        sticker = '🔗';
        errorMessage = "$sticker *Connection Timeout*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.badCertificate:
        sticker = '📜';
        errorMessage = "$sticker *Bad Certificate Error*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.connectionError:
        sticker = '🔌';
        errorMessage = "$sticker *Connection Error*\n\n"
            "$deviceSticker *Device:* $device\n"
            "💬 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioExceptionType.unknown:
      default:
        sticker = '🤷🏻‍♀️🤷🏻‍♂️';
        errorMessage = "$sticker *Unknown Error*\n\n"
            "$deviceSticker *Device:* $device\n"
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
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      String sticker = '🔴';
      String method = escapeMarkdown(response.requestOptions.method);
      String url = escapeMarkdown(response.requestOptions.uri.toString());
      String statusCode = escapeMarkdown(response.statusCode.toString());
      String requestMessage = escapeMarkdown(response.requestOptions.data?.toString() ?? 'No request data');
      String responseData = escapeMarkdown(response.data?.toString() ?? 'No response data');
      String deviceSticker = getDeviceSticker();
      String device = getDevice();

      String errorMessage = "$sticker *Bad Response*\n\n"
          "$deviceSticker *Device:* $device\n"
          "🔴 *Method:* `$method`\n"
          "⚠️ *Status Code:* `$statusCode`\n"
          "🌐 *URL:* `$url`\n"
          "📝 *Request Data:* $requestMessage\n"
          "📄 *Response Data:* $responseData";
      sendErrorToTelegram(errorMessage);
    }
    super.onResponse(response, handler);
  }

  /// Escape MarkdownV2 special characters
  String escapeMarkdown(String text) {
    return text.replaceAllMapped(
        RegExp(r'([_*`$begin:math:display$$end:math:display${}()~>#+\-=|.!])'), (match) => '\\${match[0]}');
  }

  String getDevice() {
    String device = 'Unknown Device';
    switch (Platform.operatingSystem) {
      case 'android':
        device = 'Android';
        break;
      case 'ios':
        device = 'iOS';
        break;
      case 'linux':
        device = 'Linux';
        break;
      case 'macos':
        device = 'macOS';
        break;
      case 'windows':
        device = 'Windows';
        break;
    }
    return device;
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
