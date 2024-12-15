# Changelog

## [1.2.0] - 2024-12-15

### Added
- Introduced `includeHeaders` parameter to `TelegramErrorInterceptor` to include request headers in error messages.
- Enhanced error messages with HTTP method and status code as hashtags for better filtering in Telegram.

### Changed
- Improved error message formatting by adding hashtags based on method types and status codes for better categorization.

## [1.1.1] - Updated

### Added
- Introduced `ignoreStatusCodes` parameter to `TelegramErrorInterceptor` to allow selective ignoring of specific HTTP status codes.
- Added device information retrieval functionality using the `device_info_plus` package for Android, iOS, Linux, macOS, and Windows:
    - `getDevice()` method to fetch detailed device information (e.g., Android model, iOS version).
    - `getDeviceSticker()` method to provide device-specific emoji stickers for enriched error logs.
- Enhanced error messages sent to Telegram with device details and corresponding stickers for better debugging experience.

### Changed
- Updated `sendErrorToTelegram` to include device details in error messages for better issue tracking.
- Improved error message formatting using MarkdownV2 for consistency and better readability in Telegram.
- Differentiated error handling with custom messages for `sendTimeout`, `receiveTimeout`, `connectionTimeout`, and other error types.

### Fixed
- Resolved Markdown escaping issues with a new `escapeMarkdown()` method to handle special characters correctly.

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