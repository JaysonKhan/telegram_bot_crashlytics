import 'dart:developer';

import 'package:dart_telegram_bot/dart_telegram_bot.dart';
import 'package:dart_telegram_bot/telegram_entities.dart';
import 'package:dio/dio.dart';

class TelegramErrorInterceptor extends Interceptor {
  final String botToken;
  final int chatId;

  // Singleton instansiyasi
  static TelegramErrorInterceptor? _instance;

  // Singleton konstruktor
  factory TelegramErrorInterceptor({required String botToken, required int chatId}) {
    _instance ??= TelegramErrorInterceptor._internal(botToken, chatId);
    return _instance!;
  }

  // Private konstruktor
  TelegramErrorInterceptor._internal(this.botToken, this.chatId);

  // Xatolikni Telegram botga yuborish funksiyasi
  Future<void> sendErrorToTelegram(String errorMessage) async {
    final bot = Bot(token: botToken);
    try {
      await bot.sendMessage(
        ChatID(chatId),
        errorMessage,
        parseMode: ParseMode.markdownV2,  // MarkdownV2 formatida yuborish
      );
      log('Error message sent to Telegram successfully');
    } catch (e) {
      log('Failed to send error message to Telegram: $e');
    }
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    String errorMessage;

    // Request va status code ma'lumotlarini olish
    String url = err.requestOptions.uri.toString();
    String statusCode = err.response?.statusCode?.toString() ?? 'Unknown';
    String statusMessage = err.response?.statusMessage ?? 'No status message';

    switch (err.type) {
      case DioErrorType.sendTimeout:
        errorMessage = "*Send Timeout Error*\n\n"
            "⏰ *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.receiveTimeout:
        errorMessage = "*Receive Timeout Error*\n\n"
            "⏳ *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.cancel:
        errorMessage = "*Request Cancelled*\n\n"
            "🚫 *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.connectionTimeout:
        errorMessage = "*Connection Timeout*\n\n"
            "🔗 *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.badCertificate:
        errorMessage = "*Bad Certificate Error*\n\n"
            "📜 *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.badResponse:
        errorMessage = "*Bad Response*\n\n"
            "⚠️ *Status Code:* `$statusCode`\n"
            "*Status Message:* _${escapeMarkdown(statusMessage)}_\n"
            "*URL:* `$url`\n"
            "*Error Details:* _${escapeMarkdown(err.message??'Unknown Error')}_";
        break;

      case DioErrorType.connectionError:
        errorMessage = "*Connection Error*\n\n"
            "🔌 *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;

      case DioErrorType.unknown:
      default:
        errorMessage = "*Unknown Error*\n\n"
            "❓ *Message:* _${escapeMarkdown(err.message??'Unknown Error')}_\n"
            "*URL:* `$url`";
        break;
    }

    // Xabarni Telegram'ga yuborish
    sendErrorToTelegram(errorMessage);
    handler.next(err);
  }

  // Markdown formatidagi maxsus belgilarni qochirish funksiyasi
  String escapeMarkdown(String text) {
    return text.replaceAllMapped(RegExp(r'([_*`$begin:math:display$$end:math:display$])'), (match) => '\\${match[0]}');
  }
}