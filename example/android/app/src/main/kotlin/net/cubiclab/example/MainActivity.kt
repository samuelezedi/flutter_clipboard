package net.cubiclab.example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import net.cubiclab.clipboard.ClipboardChannelHandler

class MainActivity : FlutterActivity() {
    private var clipboardHandler: ClipboardChannelHandler? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        clipboardHandler = ClipboardChannelHandler(applicationContext)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "net.cubiclab.clipboard/methods"
        ).apply { setMethodCallHandler(clipboardHandler) }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "net.cubiclab.clipboard/events"
        ).apply { setStreamHandler(clipboardHandler) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        clipboardHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
