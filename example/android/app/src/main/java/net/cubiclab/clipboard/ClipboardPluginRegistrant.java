package net.cubiclab.clipboard;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class ClipboardPluginRegistrant {
    public static void registerWith(FlutterPlugin.FlutterPluginBinding binding) {
        ClipboardPlugin plugin = new ClipboardPlugin();
        plugin.onAttachedToEngine(binding);
    }
}

