
# Telegram Bot Crashlytics

Telegram Bot Crashlytics is a package that works with the `Dio` library to send application errors directly to Telegram. With this package, you can send errors from your app to your Telegram group or channel in real-time.

<img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExemxodXByN284b3dsdnA0bWc4c3kyYW96NTc4eGVqMHV0a2s0M250NCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Zll2OF7cp3HkAhxkJM/giphy.gif" alt="Created by JaysonKhan" width="591"/>

## Features
- Automatic error reporting to Telegram.
- Monitors any HTTP errors via a `Dio` interceptor.
- Allows sending additional messages (for example, user notifications or system status updates).

## Installation

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  telegram_bot_crashlytics: ^1.0.0
```

Or, install it via the command line:

```bash
flutter pub add telegram_bot_crashlytics
```

## Usage

### 1. Creating a Bot

To create a new bot in Telegram, contact `BotFather` and obtain the bot token.

<img src="images/how_to_get_bot_token.png" alt="How to get bot token" width="300"/> <img src="images/how_to_get_chat_id.png" alt="How to get chat ID" width="300"/>

### 2. Obtaining the Telegram Chat ID

Identify the `Chat ID` of the group or channel where you want to receive messages. You can find this by sending a message to yourself or the bot and then accessing it through the API: `https://api.telegram.org/bot<your-bot-token>/getUpdates`.

### 3. Verifying the Result from Chat

After sending a test message, you should see a response similar to the following:

<img src="images/result_from_chat.png" alt="Result from chat" width="400"/>

### 4. Setting up Telegram Bot Crashlytics

Configure the package in your app as follows:

```dart
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  // Set up Telegram Bot Crashlytics
  final telegramCrashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN',
    chatId: YOUR_CHAT_ID,
  );

  // Set up Dio and add the interceptor
  final dio = Dio();
  dio.interceptors.add(telegramCrashlytics.interceptor);
}
```

### 5. Monitoring Errors

When making HTTP requests with `Dio`, errors are automatically sent to Telegram via the interceptor.

If you want to manually send a message outside of Dio errors:

```dart
await telegramCrashlytics.sendErrorToTelegram("Describe the error here.");
await telegramCrashlytics.sendInfoToTelegram("Provide additional information here.");
```

## Additional Settings

You can use the `sendErrorToTelegram` and `sendInfoToTelegram` methods to send custom messages.

<img src="images/example_function2.gif" alt="Telegram Crashlytics Demo" width="400"/>

## Example Usage

```dart
// Executing HTTP request with Dio
final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

// If an error occurs, it will be automatically sent to Telegram by the interceptor.
```

## Join Our Channel

Join our Telegram channel for updates and Flutter tips: [@FlutterMarkazi](https://t.me/FlutterMarkazi)
