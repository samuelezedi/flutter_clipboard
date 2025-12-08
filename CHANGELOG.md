## 3.0.0

* **Major Release**: Complete rewrite with platform channel support for true multi-format clipboard
* **Platform Channels**: Added native Android (Kotlin) and iOS (Objective-C) implementations for enhanced features
* **True Rich Text Support**: HTML clipboard support now works via platform channels, not just in-memory storage
* **Image Support**: Full image copy/paste support for PNG images on Android and iOS
* **Native Clipboard Monitoring**: Real-time clipboard change detection using platform APIs (Android clipboard listeners, iOS notification center)
* **Memory Management**: Fixed listener memory leaks by using Set instead of List and adding cleanup mechanisms
* **Enhanced Error Handling**: Improved error handling with graceful fallbacks to Flutter's Clipboard API
* **Better Listener Management**: `addListener()` now returns a cleanup function, added `removeAllListeners()` method
* **New Methods**: Added `copyImage()` and `pasteImage()` for direct image clipboard operations
* **Production Ready**: Comprehensive fallback mechanisms ensure reliability across all platforms
* **Documentation**: Updated README with accurate feature descriptions, image examples, and platform setup instructions
* **Code Quality**: Improved code structure, better separation of concerns, and comprehensive error handling
* **Breaking Changes**: This is a major version bump due to significant architectural improvements and platform channel integration

## 2.0.2

* **Major Improvements**: Complete rewrite with platform channel support for true multi-format clipboard
* **Platform Channels**: Added native Android (Kotlin) and iOS (Swift) implementations for enhanced features
* **True Rich Text Support**: HTML clipboard support now works via platform channels, not just in-memory storage
* **Image Support**: Full image copy/paste support for PNG images on Android and iOS
* **Native Clipboard Monitoring**: Real-time clipboard change detection using platform APIs (Android clipboard listeners)
* **Memory Management**: Fixed listener memory leaks by using Set instead of List and adding cleanup mechanisms
* **Enhanced Error Handling**: Improved error handling with graceful fallbacks to Flutter's Clipboard API
* **Better Listener Management**: `addListener()` now returns a cleanup function, added `removeAllListeners()` method
* **New Methods**: Added `copyImage()` and `pasteImage()` for direct image clipboard operations
* **Production Ready**: Comprehensive fallback mechanisms ensure reliability across all platforms
* **Documentation**: Updated README with accurate feature descriptions, image examples, and platform setup instructions
* **Code Quality**: Improved code structure, better separation of concerns, and comprehensive error handling

## 2.0.0

* **Major Release**: Fixed naming conflicts and improved API consistency
* **Class Renaming**: Renamed `ClipboardData` to `EnhancedClipboardData` to avoid conflicts with Flutter's built-in `ClipboardData`
* **API Improvements**: Better separation between Flutter's native clipboard API and enhanced features
* **Bug Fixes**: Fixed all compilation errors and linter issues

## 1.0.0

* **Major Release**: Complete rewrite with enhanced functionality
* **SDK Update**: Updated to Dart SDK >=3.0.0 <4.0.0
* **Rich Text Support**: Added `copyRichText()` and `pasteRichText()` methods
* **Multiple Format Copy**: Added `copyMultiple()` for copying multiple data formats
* **Clipboard Monitoring**: Added real-time clipboard change detection with `addListener()`, `startMonitoring()`, and `stopMonitoring()`
* **Enhanced Error Handling**: Custom `ClipboardException` class with error codes
* **Utility Methods**: Added `hasData()`, `isEmpty()`, `getContentType()`, `getDataSize()`, `isValidInput()`, and `clear()`
* **Callback Support**: Added `copyWithCallback()` with success and error callbacks
* **Debug Information**: Added `getDebugInfo()` for comprehensive debugging
* **Testing Support**: Added `setMockData()` for testing scenarios
* **ClipboardData Class**: New data class with rich information about clipboard content
* **ClipboardContentType Enum**: Enum for identifying clipboard content types
* **Backward Compatibility**: All original methods (`copy`, `paste`, `controlC`, `controlV`) still supported
* **Improved Documentation**: Comprehensive README with examples for all features
* **Enhanced Example App**: Complete demo showcasing all new features

## 0.1.3

* Added null safety

## 0.1.2+8

* Fixed bug in clipboard class
* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+7

* Fixed bug in clipboard class
* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+6

* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+5

* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+4

* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+3

* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+2

* No major changes, edited readme, changelog, pubspec.yaml.

## 0.1.2+1

* No major changes, just a few tweaks in readme, changelog.

## 0.1.2

* No major changes, just a few tweaks in readme, changelog, example director etc.

## 0.1.1

* First release
* User can Copy from clipboard
* User can Paste from cliboard,