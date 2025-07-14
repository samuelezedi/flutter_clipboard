# Enhanced Flutter Clipboard

[![pub package](https://img.shields.io/badge/2.0.0-brightgreen)](https://github.com/samuelezedi/flutter_clipboard)

A powerful Flutter package that provides comprehensive clipboard functionality with rich text support, monitoring, and advanced features.

[GitHub](https://github.com/samuelezedi/flutter_clipboard)

## Features

- ✅ **Basic Copy/Paste**: Simple text copying and pasting
- ✅ **Rich Text Support**: Copy and paste HTML-formatted text
- ✅ **Multiple Formats**: Copy multiple data formats simultaneously
- ✅ **Clipboard Monitoring**: Real-time clipboard change detection
- ✅ **Error Handling**: Comprehensive error handling with custom exceptions
- ✅ **Utility Methods**: Check clipboard status, size, and content type
- ✅ **Callback Support**: Success and error callbacks for operations
- ✅ **Debug Information**: Get detailed clipboard debugging info
- ✅ **Cross-Platform**: Works on Android, iOS, and Web
- ✅ **Null Safety**: Full null safety support

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  clipboard: ^2.0.0
```

## Basic Usage

```dart
import 'package:clipboard/clipboard.dart';
```

### Copy to clipboard

```dart
// Basic copy
await FlutterClipboard.copy('Hello Flutter friends');

// Copy with error handling
try {
  await FlutterClipboard.copy('Hello World');
  print('Text copied successfully!');
} on ClipboardException catch (e) {
  print('Copy failed: ${e.message}');
}
```

### Paste from clipboard

```dart
// Basic paste
String text = await FlutterClipboard.paste();

// Paste with error handling
try {
  String text = await FlutterClipboard.paste();
  setState(() {
    myTextField.text = text;
  });
} on ClipboardException catch (e) {
  print('Paste failed: ${e.message}');
}
```

## Advanced Features

### Rich Text Support

```dart
// Copy rich text with HTML
await FlutterClipboard.copyRichText(
  text: 'Hello World',
  html: '<b>Hello</b> <i>World</i>',
);

// Paste rich text
EnhancedClipboardData data = await FlutterClipboard.pasteRichText();
print('Text: ${data.text}');
print('HTML: ${data.html}');
```

### Multiple Format Copy

```dart
// Copy multiple formats simultaneously
await FlutterClipboard.copyMultiple({
  'text/plain': 'Hello World',
  'text/html': '<b>Hello World</b>',
  'custom/format': 'Custom data',
});
```

### Callback Support

```dart
// Copy with success/error callbacks
await FlutterClipboard.copyWithCallback(
  text: 'Hello World',
  onSuccess: () {
    print('Copy successful!');
    showSnackBar('Text copied to clipboard');
  },
  onError: (error) {
    print('Copy failed: $error');
    showSnackBar('Copy failed: $error');
  },
);
```

### Clipboard Monitoring

```dart
// Add clipboard change listener
void onClipboardChanged(EnhancedClipboardData data) {
  print('Clipboard changed: ${data.text}');
}

FlutterClipboard.addListener(onClipboardChanged);

// Start automatic monitoring
FlutterClipboard.startMonitoring(interval: Duration(milliseconds: 500));

// Stop monitoring
FlutterClipboard.stopMonitoring();

// Remove listener
FlutterClipboard.removeListener(onClipboardChanged);
```

### Utility Methods

```dart
// Check if clipboard has content
bool hasData = await FlutterClipboard.hasData();

// Check if clipboard is empty
bool isEmpty = await FlutterClipboard.isEmpty();

// Get clipboard content type
ClipboardContentType type = await FlutterClipboard.getContentType();

// Get clipboard data size
int size = await FlutterClipboard.getDataSize();

// Validate input before copying
bool isValid = FlutterClipboard.isValidInput('Hello World');

// Clear clipboard
await FlutterClipboard.clear();
```

### Debug Information

```dart
// Get comprehensive debug information
Map<String, dynamic> debugInfo = await FlutterClipboard.getDebugInfo();
print(debugInfo);
// Output: {
//   'hasData': true,
//   'contentType': 'ClipboardContentType.text',
//   'dataSize': 11,
//   'listenersCount': 2,
//   'isMonitoring': true,
//   'lastData': 'Hello World'
// }
```

## EnhancedClipboardData Class

The `EnhancedClipboardData` class provides rich information about clipboard content:

```dart
EnhancedClipboardData data = await FlutterClipboard.pasteRichText();

// Check content types
if (data.hasText) print('Has text: ${data.text}');
if (data.hasHtml) print('Has HTML: ${data.html}');
if (data.hasImage) print('Has image data');
if (data.hasFiles) print('Has file paths');

// Check if completely empty
if (data.isEmpty) print('Clipboard is empty');

// Get timestamp
print('Copied at: ${data.timestamp}');
```

## Error Handling

The package provides custom exceptions for better error handling:

```dart
try {
  await FlutterClipboard.copy('');
} on ClipboardException catch (e) {
  print('Error: ${e.message}');
  print('Error code: ${e.code}');
}
```

Common error codes:
- `EMPTY_TEXT`: Attempted to copy empty text
- `COPY_ERROR`: General copy operation failed
- `PASTE_ERROR`: General paste operation failed
- `EMPTY_CONTENT`: No content provided for rich text copy
- `EMPTY_FORMATS`: No formats provided for multiple format copy

## Content Types

The `ClipboardContentType` enum provides information about clipboard content:

```dart
ClipboardContentType type = await FlutterClipboard.getContentType();

switch (type) {
  case ClipboardContentType.text:
    print('Plain text content');
    break;
  case ClipboardContentType.html:
    print('HTML content');
    break;
  case ClipboardContentType.mixed:
    print('Mixed content (text + HTML)');
    break;
  case ClipboardContentType.empty:
    print('Empty clipboard');
    break;
  case ClipboardContentType.unknown:
    print('Unknown content type');
    break;
}
```

## Legacy Methods

For backward compatibility, the original methods are still available:

```dart
// Legacy methods (still supported)
bool success = await FlutterClipboard.controlC('Hello World');
dynamic data = await FlutterClipboard.controlV();
```

## Testing

The package includes comprehensive testing utilities:

```dart
// Set mock data for testing
await FlutterClipboard.setMockData('Test data');

// Get debug information for testing
Map<String, dynamic> info = await FlutterClipboard.getDebugInfo();
```

## Why This Enhanced Package?

I originally built this package 4 years ago for basic clipboard functionality. Over time, I realized developers needed more advanced features:

- **Rich Text Support**: Many apps need to preserve formatting
- **Monitoring**: Real-time clipboard change detection
- **Better Error Handling**: Proper exceptions instead of generic errors
- **Utility Methods**: Check clipboard status and content type
- **Debug Support**: Comprehensive debugging information
- **Modern API**: Updated to latest Dart/Flutter standards

This enhanced version maintains backward compatibility while adding powerful new features that modern Flutter apps need.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Follow Me

- [GitHub](https://github.com/samuelezedi)
- [Twitter](https://twitter.com/samuelezedi)
- [Medium](https://medium.com/@samuelezedi)
- [Instagram](https://instagram.com/samuelezedi)