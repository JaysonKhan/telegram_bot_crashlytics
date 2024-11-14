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

    /// Get the request URL, status code and status message
    String url = escapeMarkdown(err.requestOptions.uri.toString());
    String statusCode = escapeMarkdown(err.response?.statusCode?.toString() ?? 'Unknown');
    String statusMessage = escapeMarkdown(err.response?.statusMessage ?? 'No status message');
    String errMessage = escapeMarkdown(err.message ?? 'Unknown Error');

    /// Find out the error type and create an error message
    switch (err.type) {
      case DioErrorType.sendTimeout:
        errorMessage = "*Send Timeout Error*\n\n"
            "⏰ *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.receiveTimeout:
        errorMessage = "*Receive Timeout Error*\n\n"
            "⏳ *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.cancel:
        errorMessage = "*Request Cancelled*\n\n"
            "🚫 *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.connectionTimeout:
        errorMessage = "*Connection Timeout*\n\n"
            "🔗 *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.badCertificate:
        errorMessage = "*Bad Certificate Error*\n\n"
            "📜 *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.badResponse:
        errorMessage = "*Bad Response*\n\n"
            "⚠️ *Status Code:* `$statusCode`\n"
            "*Status Message:* _${statusMessage}_\n"
            "*URL:* `$url`\n"
            "*Error Details:* _${errMessage}_";
        break;

      case DioErrorType.connectionError:
        errorMessage = "*Connection Error*\n\n"
            "🔌 *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.unknown:
      default:
        errorMessage = "*Unknown Error*\n\n"
            "❓ *Message:* _${errMessage}_\n"
            "*URL:* `$url`";
        break;
    }

    /// Send error message to Telegram
    sendErrorToTelegram(errorMessage);

    /// Call the next error handler
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      String method = escapeMarkdown(response.requestOptions.method);
      String url = escapeMarkdown(response.requestOptions.uri.toString());
      String statusCode = escapeMarkdown(response.statusCode.toString());
      String statusMessage = escapeMarkdown(response.statusMessage ?? 'No status message');
      String responseData = escapeMarkdown(response.data?.toString() ?? 'No response data');

      String errorMessage = "*Bad Response*\n\n"
          "🔴 *Method:* `$method`\n"
          "⚠️ *Status Code:* `$statusCode`\n"
          "*Status Message:* _${statusMessage}_\n"
          "*URL:* `$url`\n"
          "*Response Data:* _${responseData}_";
      sendErrorToTelegram(errorMessage);
    }
    super.onResponse(response, handler);
  }

  /// Escape MarkdownV2 special characters
  String escapeMarkdown(String text) {
    return text.replaceAllMapped(RegExp(r'([_*`\[\]{}()~>#+\-=|.!])'), (match) => '\\${match[0]}');
  }
}
