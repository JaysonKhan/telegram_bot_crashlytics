
# Telegram Bot Crashlytics

Telegram Bot Crashlytics - bu `Dio` kutubxonasi bilan ishlaydigan va ilova xatolarini Telegram orqali jo'natish imkonini beruvchi paket. Bu paket yordamida ilovangizdagi xatolar to'g'ridan-to'g'ri Telegram guruhingiz yoki kanalingizga yuboriladi va real vaqt rejimida kuzatiladi.

![Telegram Bot Crashlytics](example_function1.png)

## Xususiyatlar
- Xatolarni Telegramga avtomatik yuborish.
- `Dio` interceptor orqali har qanday HTTP xatolarni kuzatish.
- Qo'shimcha xabarlarni ham yuborish imkoniyati (masalan, foydalanuvchiga xabar berish yoki tizim holatini kuzatish).

## O'rnatish

`pubspec.yaml` faylingizga quyidagi qatorni qo'shing:

```yaml
dependencies:
  telegram_bot_crashlytics: ^1.0.0
```

Yoki terminal orqali quyidagi buyrug'ni ishlatib o'rnatishingiz mumkin:

```bash
flutter pub add telegram_bot_crashlytics
```

## Ishlatish

### 1. Bot yaratish

Telegram orqali yangi bot yaratish uchun `BotFather` bilan bog'laning va bot tokenini oling.

### 2. Telegram Chat ID olish

Xabarlarni qabul qilmoqchi bo'lgan guruh yoki kanalingizning `Chat ID`sini aniqlang. Buning uchun o'zingiz yoki botga `https://api.telegram.org/bot<your-bot-token>/getUpdates` API orqali yuborilgan xabarlar orqali aniqlash mumkin.

### 3. Telegram Bot Crashlytics’ni sozlash

Paketni dasturingizda quyidagi tarzda sozlang:

```dart
import 'package:telegram_bot_crashlytics/telegram_bot_crashlytics.dart';

void main() {
  // Telegram Bot Crashlytics-ni sozlash
  final telegramCrashlytics = TelegramBotCrashlytics(
    botToken: 'YOUR_BOT_TOKEN',
    chatId: YOUR_CHAT_ID,
  );

  // Dio-ni sozlash va interceptor qo'shish
  final dio = Dio();
  dio.interceptors.add(telegramCrashlytics.interceptor);
}
```

### 4. Xatolarni kuzatish

`Dio` orqali HTTP so'rovlarini amalga oshirishda xatolar avtomatik ravishda Telegram orqali yuboriladi. Agar qo'lda xabar yubormoqchi bo'lsangiz:

```dart
await telegramCrashlytics.sendErrorToTelegram("Bu yerda xatolik haqida xabar yozing.");
await telegramCrashlytics.sendInfoToTelegram("Bu yerda qo'shimcha ma'lumot yuboring.");
```

## Qo'shimcha Sozlamalar

`sendErrorToTelegram` va `sendInfoToTelegram` usullari yordamida qo'shimcha xabarlarni jo'natishingiz mumkin.

![Telegram Crashlytics Demo](example_function2.gif)

## Misol Keltirish

```dart
try {
  // HTTP so'rov amalga oshirilmoqda
  final response = await dio.get('https://jsonplaceholder.typicode.com/posts');
} catch (e) {
  // Xato yuz berganda Telegramga xabar yuborish
  await telegramCrashlytics.sendErrorToTelegram("HTTP so'rovda xatolik yuz berdi: $e");
}
```

## Kanalimizga qo'shiling

Yangiliklar va Flutter bo'yicha maslahatlar uchun Telegram kanalimizga qo'shiling: [@FlutterMarkazi](https://t.me/FlutterMarkazi)
