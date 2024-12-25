
# Telegram Bot Crashlytics

Telegram Bot Crashlytics is a package that works with the `Dio` library to send application errors directly to Telegram and Slack. With this package, you can send errors from your app to your Telegram group, channel, or Slack workspace in real-time.

![Created by JaysonKhan](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExemxodXByN284b3dsdnA0bWc4c3kyYW96NTc4eGVqMHV0a2s0M250NCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Zll2OF7cp3HkAhxkJM/giphy.gif)

---

## Features
- **Automatic error reporting to Telegram and Slack.**
- Monitors any HTTP errors via a `Dio` interceptor.
- Allows sending additional messages (for example, user notifications or system status updates).
- Retrieves detailed device information and appends it to error messages for enhanced debugging.
- Lets you selectively ignore specific HTTP status codes with the `ignoreStatusCodes` parameter.
- **New:** Supports sending formatted error messages to Slack using a Webhook URL.
- **New:** Include request headers in error messages using the `includeHeaders` parameter.
- **New:** Errors are categorized with hashtags for HTTP method types and status codes.

---

## Installation

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  telegram_bot_crashlytics: ^1.3.4
```

Or, install it via the command line:

```bash
flutter pub add telegram_bot_crashlytics
```

> **Note:** If you encounter any issues with the latest version, consider using version `1.2.4` for stability.

---

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

---

### 3. Setting up Telegram Bot Crashlytics

Configure the package in your app as follows:

```dart
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  final telegramCrashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN',
    chatId: YOUR_CHAT_ID,
    ignoreStatusCodes: [400, 404], // Specify status codes to ignore
    includeHeaders: true, // Include request headers in error messages
    slackWebhookUrl: 'YOUR_SLACK_WEBHOOK_URL', // Optional: Slack integration
  );

  final dio = Dio();
  dio.interceptors.add(telegramCrashlytics.interceptor);
}
```

---

### 4. Sending Errors Manually

When making HTTP requests with `Dio`, errors are automatically sent to Telegram and Slack via the interceptor.

If you want to manually send a message outside of Dio errors:

```dart
// Send error messages manually to Telegram
await telegramCrashlytics.sendErrorToTelegram("Describe the error here.");

// Send informational messages manually to Telegram
await telegramCrashlytics.sendInfoToTelegram("Provide additional information here.");
```

---

### 5. Slack Integration

#### How to Get a Slack Webhook URL:
1. Open Slack and navigate to your workspace.
2. Go to **Settings & Administration > Manage Apps**.
3. Search for **"Incoming Webhooks"** and add it to your workspace.
4. Create a new Webhook and copy the generated URL.
5. Pass the Webhook URL when initializing `TelegramBotCrashlytics`.

#### Slack Integration Example:

```dart
final telegramCrashlytics = TelegramBotCrashlytics(
  botToken: 'YOUR_TELEGRAM_BOT_TOKEN',
  chatId: YOUR_CHAT_ID,
  ignoreStatusCodes: [],
  includeHeaders: true,
  slackWebhookUrl: 'YOUR_SLACK_WEBHOOK_URL', // Required for Slack
);
```

With Slack integration, all error messages are sent to your specified Slack channel.

---

### 6. Additional Settings

- **Device Information**:
  - Automatically adds device details (e.g., Android model, iOS version) to error messages.
  - Each device type is represented with an emoji sticker for quick identification.

- **Selective Ignoring of HTTP Status Codes**:
  - Use the `ignoreStatusCodes` parameter to exclude specific status codes from being sent to Telegram or Slack.

---

### Example

```dart
// Executing HTTP request with Dio
final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

// If an error occurs, it will be automatically sent to Telegram and Slack by the interceptor.
```

---

## Join Our Channel

Join our Telegram channel for updates and Flutter tips: [@FlutterMarkazi](https://t.me/FlutterMarkazi)

---

## Support the Project

If you like this project and want to support me, consider buying me a coffee or donating via USDT TRC20:

- **Buy Me a Coffee**: [KHAN347](https://www.buymeacoffee.com/khan347)
- **USDT TRC20 Wallet**: `TPXnvYAYcsf1tMrqWfpmDy5swFpiJ737br`

---

## Check Out My Other Package!

Looking for efficient network caching for your HTTP requests? Check out my other Dart/Flutter package:  
👉 [Network Cache Interceptor](https://pub.dev/packages/network_cache_interceptor)

---

### What’s New in 1.3.4?

- Added **Slack Integration** for sending errors to your Slack workspace via Webhook.
- Enhanced error formatting for both Telegram and Slack.
- Improved device-specific details for better debugging.
- Optimized request and response data logging.
