# Changelog

## TODO
- Added a web example
- Added a utility method to time async events (`Analytics.startTimer()`)
- Updated the readme to add information about when we send analytics info

## 0.0.5

- Catch errors during pings to Google Analytics, for example in case of a
  missing internet connection
- Track additional browser data, such as screen size and language
- Added tests for `usage` running in a dart:html context
- Changed to a custom implementation of UUID; saved ~376k in compiled JS size

## 0.0.4

- Moved `sanitizeStacktrace` into the main library

## 0.0.3

- Replaced optional positional arguments with named arguments
- Added code coverage! Thanks to https://github.com/Adracus/dart-coveralls and
  coveralls.io.

## 0.0.2

- Fixed a bug in `analytics.sendTiming()`

## 0.0.1

- Initial version, created by Stagehand
