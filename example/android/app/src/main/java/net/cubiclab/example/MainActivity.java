package net.cubiclab.example;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import net.cubiclab.clipboard.ClipboardChannelHandler;

public class MainActivity extends FlutterActivity {
    private ClipboardChannelHandler clipboardHandler;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Register clipboard channels with ALL features (text, HTML, images, monitoring, etc.)
        clipboardHandler = new ClipboardChannelHandler(getApplicationContext());
        
        methodChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            "net.cubiclab.clipboard/methods"
        );
        methodChannel.setMethodCallHandler(clipboardHandler);
        
        eventChannel = new EventChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            "net.cubiclab.clipboard/events"
        );
        eventChannel.setStreamHandler(clipboardHandler);
    }

    @Override
    public void cleanUpFlutterEngine(FlutterEngine flutterEngine) {
        if (methodChannel != null) {
            methodChannel.setMethodCallHandler(null);
        }
        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
        }
        clipboardHandler = null;
        super.cleanUpFlutterEngine(flutterEngine);
    }
}
