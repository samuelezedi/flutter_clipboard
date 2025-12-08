import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:js_util' as jsu;

// Web implementation using browser Clipboard API (requires user gesture)
Future<void> copyImageWebImpl(Uint8List imageBytes) async {
  // Ensure browser clipboard API is available
  final clipboard = jsu.getProperty(html.window.navigator, 'clipboard');
  if (clipboard == null) {
    throw Exception('Clipboard API is not available in this browser');
  }

  try {
    final blob = html.Blob([imageBytes], 'image/png');

    // Construct ClipboardItem via JS interop:
    // new ClipboardItem({ 'image/png': blob })
    final clipboardItemCtor = jsu.getProperty(jsu.globalThis, 'ClipboardItem');
    if (clipboardItemCtor == null) {
      throw Exception('ClipboardItem is not supported in this browser');
    }
    final clipboardItem =
        jsu.callConstructor(clipboardItemCtor, [jsu.jsify({'image/png': blob})]);

    // Call navigator.clipboard.write([clipboardItem])
    await jsu.promiseToFuture(
      jsu.callMethod(clipboard, 'write', [
        jsu.jsify([clipboardItem]),
      ]),
    );
  } catch (e) {
    throw Exception('Failed to copy image to clipboard: $e');
  }
}

Future<Uint8List?> pasteImageWebImpl() async {
  final clipboard = jsu.getProperty(html.window.navigator, 'clipboard');
  if (clipboard == null) {
    return null;
  }

  try {
    // navigator.clipboard.read()
    final items = await jsu.promiseToFuture<List<dynamic>>(
      jsu.callMethod(clipboard, 'read', []),
    );

    for (final item in items) {
      // item.types is JS array
      final types = jsu.getProperty(item, 'types') as List<dynamic>?;
      if (types == null) continue;
      if (!types.contains('image/png')) continue;

      // item.getType('image/png') -> Promise<Blob>
      final blob = await jsu.promiseToFuture<html.Blob>(
        jsu.callMethod(item, 'getType', ['image/png']),
      );

      // blob.arrayBuffer() -> Promise<ArrayBuffer>
      final arrayBuffer = await jsu.promiseToFuture<Object>(
        jsu.callMethod(blob, 'arrayBuffer', []),
      );

      // Convert ArrayBuffer to Uint8List
      final bytes = Uint8List.view((arrayBuffer as ByteBuffer));
      return bytes;
    }
    return null;
  } catch (e) {
    return null;
  }
}

// Web implementation for pasting text
Future<String> pasteTextWebImpl() async {
  final clipboard = jsu.getProperty(html.window.navigator, 'clipboard');
  if (clipboard == null) {
    throw Exception('Clipboard API is not available in this browser');
  }

  try {
    // navigator.clipboard.readText()
    final text = await jsu.promiseToFuture<String>(
      jsu.callMethod(clipboard, 'readText', []),
    );
    return text;
  } catch (e) {
    throw Exception('Failed to paste text from clipboard: $e');
  }
}

// Web implementation for pasting rich text (text + HTML)
Future<Map<String, dynamic>> pasteRichTextWebImpl() async {
  final clipboard = jsu.getProperty(html.window.navigator, 'clipboard');
  if (clipboard == null) {
    throw Exception('Clipboard API is not available in this browser');
  }

  try {
    String? text;
    String? htmlText;

    // Try to read text
    try {
      text = await jsu.promiseToFuture<String>(
        jsu.callMethod(clipboard, 'readText', []),
      );
    } catch (e) {
      // Text might not be available
    }

    // Try to read HTML from clipboard items
    try {
      // navigator.clipboard.read()
      final items = await jsu.promiseToFuture<List<dynamic>>(
        jsu.callMethod(clipboard, 'read', []),
      );

      for (final item in items) {
        // item.types is JS array
        final types = jsu.getProperty(item, 'types') as List<dynamic>?;
        if (types == null) continue;

        // Check for HTML
        if (types.contains('text/html')) {
          // item.getType('text/html') -> Promise<Blob>
          final blob = await jsu.promiseToFuture<html.Blob>(
            jsu.callMethod(item, 'getType', ['text/html']),
          );

          // blob.text() -> Promise<String>
          htmlText = await jsu.promiseToFuture<String>(
            jsu.callMethod(blob, 'text', []),
          );
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
