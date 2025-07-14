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