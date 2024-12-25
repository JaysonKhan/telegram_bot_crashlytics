library;

import 'package:dio/dio.dart';
import 'package:telegram_bot_crashlytics/interceptor/telegram_error_interceptor.dart';

/// A utility class to send error and informational messages to Telegram and Slack.
/// Integrates with Dio to automatically intercept HTTP errors.
///
/// Key Features:
/// - Send error and informational messages to Telegram.
/// - Optionally send error messages to Slack.
/// - Include HTTP headers and ignore specific status codes.
/// - Integrate with Dio as an interceptor.
class TelegramBotCrashlytics {
  /// Telegram Bot Token: The token of the bot that will send the error messages.
  ///
  /// Required. Obtain this from `BotFather` in Telegram.
  final String botToken;

  /// Telegram Chat ID: The ID of the chat where the error messages will be sent.
  ///
  /// Required. This can be a group, channel, or user ID.
  final int chatId;

  /// Slack Webhook URL: The URL to send messages to Slack.
  ///
  /// Optional. Obtain this by creating a webhook in your Slack workspace.
  final String? slackWebhookUrl;

  /// HTTP status codes to ignore when sending error messages.
  ///
  /// Default: Empty list (no codes are ignored).
  final List<int> ignoreStatusCodes;

  /// Whether to include HTTP headers in the error messages.
  ///
  /// Default: `false`.
  final bool includeHeaders;

  /// Singleton instance for global access.
  static TelegramBotCrashlytics? _instance;

  /// Private named constructor for initializing the class.
  TelegramBotCrashlytics._internal({
    required this.botToken,
    required this.chatId,
    this.slackWebhookUrl,
    required this.ignoreStatusCodes,
    required this.includeHeaders,
  }) {
    _telegramErrorInterceptor = TelegramErrorInterceptor(
      botToken: botToken,
      chatId: chatId,
      ignoreStatusCodes: ignoreStatusCodes,
      includeHeaders: includeHeaders,
      slackWebhookUrl: slackWebhookUrl,
    );
  }

  /// Factory constructor for creating or accessing the singleton instance.
  ///
  /// Example:
  /// ```dart
  /// final crashlytics = TelegramBotCrashlytics(
  ///   botToken: 'YOUR_TELEGRAM_BOT_TOKEN',
  ///   chatId: 123456789,
  ///   slackWebhookUrl: 'YOUR_SLACK_WEBHOOK_URL', // Optional
  ///   ignoreStatusCodes: [400, 404],
  ///   includeHeaders: true,
  /// );
  /// ```
  factory TelegramBotCrashlytics({
    required String botToken,
    required int chatId,
    String? slackWebhookUrl,
    List<int>? ignoreStatusCodes,
    bool? includeHeaders,
  }) {
    _instance ??= TelegramBotCrashlytics._internal(
      botToken: botToken,
      chatId: chatId,
      slackWebhookUrl: slackWebhookUrl,
      ignoreStatusCodes: ignoreStatusCodes ?? [],
      includeHeaders: includeHeaders ?? false,
    );
    return _instance!;
  }

  late final TelegramErrorInterceptor _telegramErrorInterceptor;

  /// Provides the interceptor for Dio integration.
  Interceptor get interceptor => _telegramErrorInterceptor;

  /// Access the singleton instance of `TelegramBotCrashlytics`.
  ///
  /// Throws an exception if the instance is not initialized.
  static TelegramBotCrashlytics get instance {
    if (_instance == null) {
      throw Exception(
          "TelegramBotCrashlytics instance not initialized. Please call the constructor first.");
    }
    return _instance!;
  }

  /// Sends an error message to Telegram.
  ///
  /// Example:
  /// ```dart
  /// await crashlytics.sendErrorToTelegram("An error occurred!");
  /// ```
  Future<void> sendErrorToTelegram(String errorMessage) async {
    if (errorMessage.isEmpty) return;
    await _telegramErrorInterceptor.sendErrorToTelegram(
        "🚨 *Error occurred in the application*\n\n📝 *Message:* _${errorMessage}_");
  }

  /// Sends an informational message to Telegram.
  ///
  /// Example:
  /// ```dart
  /// await crashlytics.sendInfoToTelegram("Everything is working fine!");
  /// ```
  Future<void> sendInfoToTelegram(String message) async {
    if (message.isEmpty) return;
    await _telegramErrorInterceptor
        .sendErrorToTelegram("📢 *Information*\n\n📝 *Message:* _${message}_");
  }

  /// Sends an error message to Slack.
  ///
  /// Requires `slackWebhookUrl` to be set during initialization.
  ///
  /// Example:
  /// ```dart
  /// await crashlytics.sendErrorToSlack("An error occurred!");
  /// ```
  Future<void> sendErrorToSlack(String errorMessage) async {
    if (slackWebhookUrl == null || errorMessage.isEmpty) return;

    final dio = Dio();
    try {
      await dio.post(
        slackWebhookUrl!,
        data: {"text": errorMessage}, // Slack requires plain text messages.
        options: Options(headers: {"Content-Type": "application/json"}),
      );
    } catch (e) {
      print("Failed to send error message to Slack: $e");
    }
  }

  /// Sends an error message to both Telegram and Slack.
  ///
  /// Example:
  /// ```dart
  /// await crashlytics.sendErrorToBoth("Critical failure!");
  /// ```
  Future<void> sendErrorToBoth(String errorMessage) async {
    await sendErrorToTelegram(errorMessage);
    await sendErrorToSlack(errorMessage);
  }
}