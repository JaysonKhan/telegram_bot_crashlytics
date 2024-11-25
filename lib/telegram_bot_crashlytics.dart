library;

import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/interceptor/telegram_error_interceptor.dart';

class TelegramBotCrashlytics {
  /// Telegram Bot Token: The token of the bot that will send the error messages
  final String botToken;

  /// Telegram Chat ID: The ID of the chat where the error messages will be sent
  final int chatId;

  final List<int> ignoreStatusCodes;

  static TelegramBotCrashlytics? _instance;

  TelegramBotCrashlytics._internal({
    required this.botToken,
    required this.chatId,
    required this.ignoreStatusCodes,
  }) {
    _telegramErrorInterceptor = TelegramErrorInterceptor(
        botToken: botToken,
        chatId: chatId,
        ignoreStatusCodes: ignoreStatusCodes);
  }

  factory TelegramBotCrashlytics(
      {required String botToken,
      required int chatId,
      List<int>? ignoreStatusCodes}) {
    _instance ??= TelegramBotCrashlytics._internal(
        botToken: botToken,
        chatId: chatId,
        ignoreStatusCodes: ignoreStatusCodes ?? []);
    return _instance!;
  }

  late final TelegramErrorInterceptor _telegramErrorInterceptor;

  Interceptor get interceptor => _telegramErrorInterceptor;

  static TelegramBotCrashlytics get instance {
    if (_instance == null) {
      throw Exception(
          "TelegramBotCrashlytics instance not initialized. Please call the constructor first.");
    }
    return _instance!;
  }

  /// Send error message to Telegram function
  Future<void> sendErrorToTelegram(String errorMessage) async {
    if (errorMessage.isEmpty) return;
    await _telegramErrorInterceptor.sendErrorToTelegram(
        "🚨 *Error occurred in the application*\n\n📝 *Message:* _${errorMessage}_");
  }

  Future<void> sendInfoToTelegram(String message) async {
    if (message.isEmpty) return;
    await _telegramErrorInterceptor
        .sendErrorToTelegram("📢 *Information*\n\n📝 *Message:* _${message}_");
  }
}
