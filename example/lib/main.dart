import 'dart:async';

import 'package:flutter/material.dart';
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  final crashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN',
    chatId: 123456789,
  );
  // If you wand add to dio interceptor
  // final dio = Dio();
  // dio.interceptors.add(crashlytics.interceptor);

  runZonedGuarded(
    () => const MyApp(),
    (error, stack) {
      crashlytics.sendErrorToTelegram('Error: $error\nStack: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Example app for Telegram Bot Crashlytics'),
        ),
        body: const Center(
          child: Text('Hello, World!'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            TelegramBotCrashlytics.instance
                .sendInfoToTelegram('Example info message');
          },
          child: const Icon(Icons.send),
        ),
      ),
    );
  }
}
