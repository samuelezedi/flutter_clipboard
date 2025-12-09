import 'dart:async';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

// Web implementation using browser Clipboard API (requires user gesture)
Future<void> copyImageWebImpl(Uint8List imageBytes) async {
  final clipboard = web.window.navigator.clipboard;

  try {
    // Create Blob from image bytes
    final blobParts = [imageBytes.toJS].toJS;
    final blobOptions = web.BlobPropertyBag(type: 'image/png');
    final blob = web.Blob(blobParts, blobOptions);

    // Construct ClipboardItem with image/png type
    final clipboardItemData = <String, JSAny?>{'image/png': blob}.jsify()!;
    final clipboardItem = web.ClipboardItem(clipboardItemData as JSObject);

    // Call navigator.clipboard.write([clipboardItem])
    await clipboard.write([clipboardItem].toJS).toDart;
  } catch (e) {
    throw Exception('Failed to copy image to clipboard: $e');
  }
}

Future<Uint8List?> pasteImageWebImpl() async {
  final clipboard = web.window.navigator.clipboard;

  try {
    // navigator.clipboard.read() returns JSPromise<ClipboardItems>
    final items = await clipboard.read().toDart;
    final itemsList = items.toDart;
    
    for (var i = 0; i < itemsList.length; i++) {
      final item = itemsList[i];
      
      // Check if item has image/png type
      final types = item.types.toDart;
      if (!types.contains('image/png')) continue;

      // item.getType('image/png') -> Promise<Blob>
      final blob = await item.getType('image/png').toDart;

      // blob.arrayBuffer() -> Promise<ArrayBuffer>
      final arrayBuffer = await blob.arrayBuffer().toDart;

      // Convert ArrayBuffer to Uint8List
      final bytes = arrayBuffer.toDart.asUint8List();
      return bytes;
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Web implementation for pasting text
Future<String> pasteTextWebImpl() async {
  final clipboard = web.window.navigator.clipboard;

  try {
    // navigator.clipboard.readText() returns JSPromise<JSString>
    final text = await clipboard.readText().toDart;
    return text.toDart;
  } catch (e) {
    throw Exception('Failed to paste text from clipboard: $e');
  }
}

// Web implementation for pasting rich text (text + HTML)
Future<Map<String, dynamic>> pasteRichTextWebImpl() async {
  final clipboard = web.window.navigator.clipboard;

  try {
    String? text;
    String? htmlText;

    // Try to read text
    try {
      final textResult = await clipboard.readText().toDart;
      text = textResult.toDart;
    } catch (e) {
      // Text might not be available
    }

    // Try to read HTML from clipboard items
    try {
      final items = await clipboard.read().toDart;
      final itemsList = items.toDart;

      for (var i = 0; i < itemsList.length; i++) {
        final item = itemsList[i];
        final types = item.types.toDart;

        // Check for HTML
        if (types.contains('text/html')) {
          // item.getType('text/html') -> Promise<Blob>
          final blob = await item.getType('text/html').toDart;

          // blob.text() -> Promise<String>
          final htmlResult = await blob.text().toDart;
          htmlText = htmlResult.toDart;
          break;
        }
      }
    } catch (e) {
      // HTML might not be available
    }

    return {
      'text': text,
      'html': htmlText,
    };
  } catch (e) {
    throw Exception('Failed to paste rich text from clipboard: $e');
  }
}
