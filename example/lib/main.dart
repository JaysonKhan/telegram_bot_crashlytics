
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  // Initialize Telegram Bot Crashlytics with additional settings
  final crashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN', // Replace with your actual bot token
    chatId: 123456789, // Replace with your actual chat ID
    ignoreStatusCodes: [400, 404], // Example of status codes to ignore
    includeHeaders: true, // Include request headers in error messages
  );

  // Uncomment the following lines if you are using Dio for HTTP requests
  // final dio = Dio();
  // dio.interceptors.add(crashlytics.interceptor); // Attach the interceptor for automatic error reporting

  // Wrap the runApp call inside runZonedGuarded to catch uncaught errors globally
  runZonedGuarded(
        () {
      runApp(const MyApp());
    },
        (error, stack) {
      // Send uncaught errors and their stack traces to Telegram
      crashlytics.sendErrorToTelegram('Error: \$error\nStack: \$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget serves as the root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Use the latest Material Design version
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Example App for Telegram Bot Crashlytics'),
        ),
        body: const Center(
          child: Text('Hello, World!'), // Display a simple text message
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Send a test informational message to Telegram when the button is pressed
            TelegramBotCrashlytics.instance
                .sendInfoToTelegram('Example info message');
          },
          child: const Icon(Icons.send), // Icon for the floating action button
        ),
      ),
    );
  }
}
