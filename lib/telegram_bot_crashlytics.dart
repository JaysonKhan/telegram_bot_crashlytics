library telegram_bot_crashlytics;

import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/interceptor/telegram_error_interceptor.dart';

class TelegramBotCrashlytics {
  final String botToken;
  final int chatId;

  static TelegramBotCrashlytics? _instance;

  TelegramBotCrashlytics._internal({required this.botToken, required this.chatId}) {
    _telegramErrorInterceptor = TelegramErrorInterceptor(botToken: botToken, chatId: chatId);
  }

  factory TelegramBotCrashlytics({required String botToken, required int chatId}) {
    _instance ??= TelegramBotCrashlytics._internal(botToken: botToken, chatId: chatId);
    return _instance!;
  }

  late final TelegramErrorInterceptor _telegramErrorInterceptor;

  Interceptor get interceptor => _telegramErrorInterceptor;

  static TelegramBotCrashlytics get instance {
    if (_instance == null) {
      throw Exception("TelegramBotCrashlytics instance not initialized. Please call the constructor first.");
    }
    return _instance!;
  }
}
