library clipboard;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Custom exception for clipboard operations
class ClipboardException implements Exception {
  final String message;
  final String? code;

  ClipboardException(this.message, [this.code]);

  @override
  String toString() =>
      'ClipboardException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Enhanced data class for clipboard content
class EnhancedClipboardData {
  final String? text;
  final String? html;
  final Uint8List? imageBytes;
  final List<String>? filePaths;
  final Map<String, dynamic>? customData;
  final DateTime? timestamp;

  EnhancedClipboardData({
    this.text,
    this.html,
    this.imageBytes,
    this.filePaths,
    this.customData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isEmpty =>
      text?.isEmpty != false &&
      html?.isEmpty != false &&
      imageBytes?.isEmpty != false &&
      filePaths?.isEmpty != false;

  bool get hasText => text?.isNotEmpty == true;
  bool get hasHtml => html?.isNotEmpty == true;
  bool get hasImage => imageBytes?.isNotEmpty == true;
  bool get hasFiles => filePaths?.isNotEmpty == true;
}

/// Content type enumeration
enum ClipboardContentType { text, html, image, files, mixed, empty, unknown }

/// A Flutter Clipboard Plugin with enhanced functionality.
class FlutterClipboard {
  static final List<Function(EnhancedClipboardData)> _listeners = [];
  static Timer? _monitoringTimer;
  static EnhancedClipboardData? _lastData;

  // Private constructor to prevent instantiation
  FlutterClipboard._();

  /// Copy text to clipboard
  /// Returns void
  static Future<void> copy(String text) async {
    if (text.isEmpty) {
      throw ClipboardException('Text cannot be empty', 'EMPTY_TEXT');
    }
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _notifyListeners(EnhancedClipboardData(text: text));
    } catch (e) {
      throw ClipboardException('Failed to copy text: $e', 'COPY_ERROR');
    }
  }

  /// Copy rich text to clipboard
  static Future<void> copyRichText({required String text, String? html}) async {
    if (text.isEmpty && html?.isEmpty != false) {
      throw ClipboardException(
        'Either text or html must be provided',
        'EMPTY_CONTENT',
      );
    }

    try {
      // Flutter's ClipboardData only supports text, not html directly
      // We'll store the text and handle html separately
      await Clipboard.setData(
        ClipboardData(text: text.isNotEmpty ? text : html ?? ''),
      );
      _notifyListeners(EnhancedClipboardData(text: text, html: html));
    } catch (e) {
      throw ClipboardException(
        'Failed to copy rich text: $e',
        'COPY_RICH_ERROR',
      );
    }
  }

  /// Copy multiple formats simultaneously
  static Future<void> copyMultiple(Map<String, dynamic> formats) async {
    if (formats.isEmpty) {
      throw ClipboardException(
        'At least one format must be provided',
        'EMPTY_FORMATS',
      );
    }

    try {
      final text = formats['text/plain']?.toString();
      final html = formats['text/html']?.toString();

      await Clipboard.setData(
        ClipboardData(text: text ?? ''),
      );

      _notifyListeners(EnhancedClipboardData(
        text: text,
        html: html,
        imageBytes:
            formats['image/png'] is Uint8List ? formats['image/png'] : null,
        customData: formats,
      ));
    } catch (e) {
      throw ClipboardException(
        'Failed to copy multiple formats: $e',
        'COPY_MULTIPLE_ERROR',
      );
    }
  }

  /// Copy with success/error callbacks
  static Future<void> copyWithCallback({
    required String text,
    void Function()? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      await copy(text);
      onSuccess?.call();
    } catch (e) {
      final error = e is ClipboardException ? e.message : e.toString();
      onError?.call(error);
      rethrow;
    }
  }

  /// Paste text from clipboard
  static Future<String> paste() async {
    try {
      final data = await Clipboard.getData('text/plain');
      return data?.text?.toString() ?? "";
    } catch (e) {
      throw ClipboardException('Failed to paste text: $e', 'PASTE_ERROR');
    }
  }

  /// Paste rich text from clipboard
  static Future<EnhancedClipboardData> pasteRichText() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final htmlData = await Clipboard.getData('text/html');

      return EnhancedClipboardData(
        text: data?.text,
        html: htmlData?.text,
      );
    } catch (e) {
      throw ClipboardException(
        'Failed to paste rich text: $e',
        'PASTE_RICH_ERROR',
      );
    }
  }

  /// Get clipboard content type
  static Future<ClipboardContentType> getContentType() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final htmlData = await Clipboard.getData('text/html');

      if (data?.text?.isNotEmpty == true &&
          htmlData?.text?.isNotEmpty == true) {
        return ClipboardContentType.mixed;
      } else if (data?.text?.isNotEmpty == true) {
        return ClipboardContentType.text;
      } else if (htmlData?.text?.isNotEmpty == true) {
        return ClipboardContentType.html;
      } else {
        return ClipboardContentType.empty;
      }
    } catch (e) {
      return ClipboardContentType.unknown;
    }
  }

  /// Check if clipboard has content
  static Future<bool> hasData() async {
    try {
      final data = await Clipboard.getData('text/plain');
      return data?.text?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

  /// Check if clipboard is empty
  static Future<bool> isEmpty() async {
    return !(await hasData());
  }

  /// Clear clipboard
  static Future<void> clear() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      _notifyListeners(EnhancedClipboardData());
    } catch (e) {
      throw ClipboardException('Failed to clear clipboard: $e', 'CLEAR_ERROR');
    }
  }

  /// Get clipboard data size (approximate)
  static Future<int> getDataSize() async {
    try {
      final data = await Clipboard.getData('text/plain');
      return data?.text?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Validate input before copying
  static bool isValidInput(String text) {
    return text.isNotEmpty && text.trim().isNotEmpty;
  }

  /// Add clipboard change listener
  static void addListener(Function(EnhancedClipboardData) listener) {
    _listeners.add(listener);
  }

  /// Remove clipboard change listener
  static void removeListener(Function(EnhancedClipboardData) listener) {
    _listeners.remove(listener);
  }

  /// Start monitoring clipboard changes
  static void startMonitoring({
    Duration interval = const Duration(milliseconds: 500),
  }) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (timer) async {
      try {
        final currentData = await pasteRichText();
        if (_lastData?.text != currentData.text ||
            _lastData?.html != currentData.html) {
          _lastData = currentData;
          _notifyListeners(currentData);
        }
      } catch (e) {
        // Ignore monitoring errors
      }
    });
  }

  /// Stop monitoring clipboard changes
  static void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Get debug information
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final hasData = await FlutterClipboard.hasData();
      final contentType = await FlutterClipboard.getContentType();
      final dataSize = await FlutterClipboard.getDataSize();

      return {
        'hasData': hasData,
        'contentType': contentType.toString(),
        'dataSize': dataSize,
        'listenersCount': _listeners.length,
        'isMonitoring': _monitoringTimer?.isActive ?? false,
        'lastData': _lastData?.text,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'listenersCount': _listeners.length,
        'isMonitoring': _monitoringTimer?.isActive ?? false,
      };
    }
  }

  /// Set mock data for testing
  static Future<void> setMockData(String text) async {
    _lastData = EnhancedClipboardData(text: text);
    _notifyListeners(_lastData!);
  }

  // Legacy methods for backward compatibility
  /// controlC receives a string text and saves to Clipboard
  /// returns boolean value
  static Future<bool> controlC(String text) async {
    try {
      await copy(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// controlV retrieves the data from clipboard.
  /// same as paste
  /// But returns dynamic data
  static Future<dynamic> controlV() async {
    try {
      return await pasteRichText();
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  static void _notifyListeners(EnhancedClipboardData data) {
    for (final listener in _listeners) {
      try {
        listener(data);
      } catch (e) {
        // Ignore listener errors
      }
    }
  }
}
