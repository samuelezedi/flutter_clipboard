library clipboard;

import 'package:flutter/services.dart';

/// A Flutter Clipboard Plugin.
class FlutterClipboard{

  /// copy receives a string text and saves to Clipboard
  /// returns void
  static Future<void> copy(String text) async {
    if(text.isEmpty) {
      Clipboard.setData(ClipboardData(
          text: text
      ));
      return;
    } else{
      throw('Please enter a string');
    }
  }
  /// Paste retrieves the data from clipboard.
  static Future<String> paste() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    return data.text.toString();
  }


}
