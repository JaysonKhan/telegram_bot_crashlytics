import 'dart:developer';

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
      log('Error message sent to Telegram successfully');
    } catch (e) {
      log('Failed to send error message to Telegram: $e');
    }
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    String errorMessage;
    String sticker;

    /// Get the request URL, status code, status message, and error message
    String url = escapeMarkdown(err.requestOptions.uri.toString());
    String statusCode = escapeMarkdown(err.response?.statusCode?.toString() ?? 'Unknown');
    String statusMessage = escapeMarkdown(err.response?.statusMessage ?? 'No status message');
    String errMessage = escapeMarkdown(err.message ?? 'Unknown Error');

    /// Define sticker and create an error message with stickers for each line
    switch (err.type) {
      case DioErrorType.sendTimeout:
        sticker = '⏰';
        errorMessage = "$sticker *Send Timeout Error*\n\n"
            "⏰ *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.receiveTimeout:
        sticker = '⏳';
        errorMessage = "$sticker *Receive Timeout Error*\n\n"
            "⏳ *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.cancel:
        sticker = '🚫';
        errorMessage = "$sticker *Request Cancelled*\n\n"
            "🚫 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.connectionTimeout:
        sticker = '🔗';
        errorMessage = "$sticker *Connection Timeout*\n\n"
            "🔗 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.badCertificate:
        sticker = '📜';
        errorMessage = "$sticker *Bad Certificate Error*\n\n"
            "📜 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.badResponse:
        sticker = '⚠️';
        errorMessage = "$sticker *Bad Response*\n\n"
            "⚠️ *Status Code:* `$statusCode`\n"
            "📝 *Status Message:* $statusMessage\n"
            "🌐 *URL:* `$url`\n"
            "💥 *Error Details:* $errMessage";
        break;

      case DioErrorType.connectionError:
        sticker = '🔌';
        errorMessage = "$sticker *Connection Error*\n\n"
            "🔌 *Message:* $errMessage\n"
            "🌐 *URL:* `$url`";
        break;

      case DioErrorType.unknown:
      default:
        sticker = '❓';
        errorMessage = "$sticker *Unknown Error*\n\n"
            "❓ *Message:* $errMessage\n"
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

      String errorMessage = "$sticker *Bad Response*\n\n"
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
}
