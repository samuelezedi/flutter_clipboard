library clipboard;

import 'package:flutter/services.dart';

/// A Flutter Clipboard Plugin.
class FlutterClipboard{

  ///
  static Future<void> copy(String text) async {
    Clipboard.setData(ClipboardData(
        text: text
    ));
    return;
  }

  static Future<String> paste() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    return data.text.toString();
  }

}
