
# Telegram Bot Crashlytics

Telegram Bot Crashlytics is a package that works with the `Dio` library to send application errors directly to Telegram. With this package, you can send errors from your app to your Telegram group or channel in real-time.

![Created by JaysonKhan](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExemxodXByN284b3dsdnA0bWc4c3kyYW96NTc4eGVqMHV0a2s0M250NCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Zll2OF7cp3HkAhxkJM/giphy.gif)

## Features
- Automatic error reporting to Telegram.
- Monitors any HTTP errors via a `Dio` interceptor.
- Allows sending additional messages (for example, user notifications or system status updates).
- Retrieves detailed device information and appends it to error messages for enhanced debugging.
- Lets you selectively ignore specific HTTP status codes with the `ignoreStatusCodes` parameter.
- **New:** Include request headers in error messages using the `includeHeaders` parameter.
- **New:** Errors are categorized with hashtags for HTTP method types and status codes.

## Installation

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  telegram_bot_crashlytics: ^1.2.0
```

Or, install it via the command line:

```bash
flutter pub add telegram_bot_crashlytics
```

## Usage

### 1. Creating a Bot

To create a new bot in Telegram, contact `BotFather` and obtain the bot token.

![How to get bot token](https://github.com/JaysonKhan/telegram_bot_crashlytics/blob/master/images/how_to_get_bot_token.png?raw=true)
![How to get chat ID](https://github.com/JaysonKhan/telegram_bot_crashlytics/blob/master/images/how_to_get_chat_id.png?raw=true)

### 2. Obtaining the Telegram Chat ID

Identify the `Chat ID` of the group or channel where you want to receive messages. You can find this by sending a message to yourself or the bot and then accessing it through the API:

```
https://api.telegram.org/bot<your-bot-token>/getUpdates
```

### 3. Verifying the Result from Chat

After sending a test message, you should see a response similar to the following:

![Result from chat](https://github.com/JaysonKhan/telegram_bot_crashlytics/blob/master/images/result_from_chat.png?raw=true)

### 4. Setting up Telegram Bot Crashlytics

Configure the package in your app as follows:

```dart
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  final telegramCrashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN',
    chatId: YOUR_CHAT_ID,
    ignoreStatusCodes: [400, 404],
    includeHeaders: true, // Include request headers in error messages
  );

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

- **Device Information**:
  - Automatically adds device details (e.g., Android model, iOS version) to error messages.
  - Each device type is represented with an emoji sticker for quick identification in Telegram.

- **Selective Ignoring of HTTP Status Codes**:
  - Use the `ignoreStatusCodes` parameter to exclude specific status codes from being sent to Telegram.

### Example

```dart
// Executing HTTP request with Dio
final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

// If an error occurs, it will be automatically sent to Telegram by the interceptor.
```

## Join Our Channel

Join our Telegram channel for updates and Flutter tips: [@FlutterMarkazi](https://t.me/FlutterMarkazi)

---

## Support the Project

If you like this project and want to support me, consider buying me a coffee or donating via USDT TRC20:

- **Buy Me a Coffee**: [KHAN347](https://www.buymeacoffee.com/khan347)
- **USDT TRC20 Wallet**: `TPXnvYAYcsf1tMrqWfpmDy5swFpiJ737br`
