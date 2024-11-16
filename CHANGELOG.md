
# Changelog

## [1.0.1] - Updated

### Added
- Added an example in the `example/` directory to demonstrate basic usage of the package.

### Changed
- Replaced deprecated `DioError` with `DioException` for error handling.
- Updated to use `DioExceptionType` instead of `DioErrorType` for compatibility with the latest Dio version.

## [1.0.0] - Initial Release

### Added
- Telegram Bot Crashlytics package initialized with error logging functionality.
- Added `sendErrorToTelegram` method to log errors directly to a specified Telegram chat.
- Added `sendInfoToTelegram` method to send informational messages to Telegram.
- `TelegramErrorInterceptor` integrated with `Dio` to handle automatic error interception and logging.
- Markdown formatted messages for enhanced readability in Telegram.
