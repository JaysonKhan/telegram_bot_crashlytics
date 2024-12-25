import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  // Initialize Telegram Bot Crashlytics with Telegram bot settings and additional options
  final crashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN', // Replace with your actual Telegram bot token
    chatId: 123456789, // Replace with your actual Telegram chat ID
    ignoreStatusCodes: [
      400,
      404
    ], // Example: Status codes to be ignored for logging
    includeHeaders: true, // Option to include HTTP headers in error messages
    slackWebhookUrl:
        'YOUR_SLACK_WEBHOOK_URL', // Optional: Slack Webhook URL for Slack integration
  );

  // Wrap the `runApp` function inside `runZonedGuarded` to catch global uncaught errors
  runZonedGuarded(
    () {
      runApp(const MyApp()); // Start the Flutter app
    },
    (error, stackTrace) {
      // Send uncaught errors and stack traces to Telegram and Slack
      crashlytics
          .sendErrorToBoth('Uncaught Error: $error\nStack Trace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crashlytics Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Enable Material Design 3
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Crashlytics Example App'),
        ),
        body: const Center(
          child: Text(
            'Press the button to send a test message!',
            style: TextStyle(fontSize: 16), // Simple informative message
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Send a test informational message to both Telegram and Slack
            TelegramBotCrashlytics.instance
                .sendInfoToTelegram('This is a test informational message!');
          },
          tooltip: 'Send Test Message', // Tooltip for the button
          child: const Icon(Icons.send), // Send icon for better UX
        ),
      ),
    );
  }
}
