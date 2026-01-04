import Flutter
import UIKit

public class ClipboardPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var clipboardChangeObserver: NSObjectProtocol?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "net.cubiclab.clipboard/methods",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "net.cubiclab.clipboard/events",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = ClipboardPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "copy":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Text is required", details: nil))
                return
            }
            if text.isEmpty {
                result(FlutterError(code: "EMPTY_TEXT", message: "Text cannot be empty", details: nil))
                return
            }
            UIPasteboard.general.string = text
            result(true)
            
        case "copyRichText":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
                return
            }
            let text = args["text"] as? String ?? ""
            let html = args["html"] as? String
            
            if text.isEmpty && (html == nil || html!.isEmpty) {
                result(FlutterError(code: "EMPTY_CONTENT", message: "Either text or html must be provided", details: nil))
                return
            }
            
            if let html = html, !html.isEmpty {
                UIPasteboard.general.setValue(html, forPasteboardType: "public.html")
                if !text.isEmpty {
                    UIPasteboard.general.string = text
                }
            } else {
                UIPasteboard.general.string = text
            }
            result(true)
            
        case "copyMultiple":
            guard let args = call.arguments as? [String: Any],
                  let formats = args["formats"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
                return
            }
            if formats.isEmpty {
                result(FlutterError(code: "EMPTY_FORMATS", message: "At least one format must be provided", details: nil))
                return
            }
            
            // Handle image first (highest priority)
            if let imageBytes = formats["image/png"] as? [Int], !imageBytes.isEmpty {
                let data = Data(imageBytes.map { UInt8($0 & 0xFF) })
                if let image = UIImage(data: data) {
                    UIPasteboard.general.image = image
                    if let text = formats["text/plain"] as? String, !text.isEmpty {
                        UIPasteboard.general.string = text
                    }
                    result(true)
                    return
                }
            }
            
            // Fallback to HTML or text
            if let text = formats["text/plain"] as? String {
                UIPasteboard.general.string = text
            }
            if let html = formats["text/html"] as? String {
                UIPasteboard.general.setValue(html, forPasteboardType: "public.html")
            }
            result(true)
            
        case "copyImage":
            guard let args = call.arguments as? [String: Any],
                  let imageBytes = args["imageBytes"] as? [Int] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Image bytes are required", details: nil))
                return
            }
            if imageBytes.isEmpty {
                result(FlutterError(code: "EMPTY_IMAGE", message: "Image bytes cannot be empty", details: nil))
                return
            }
            let data = Data(imageBytes.map { UInt8($0 & 0xFF) })
            guard let image = UIImage(data: data) else {
                result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image", details: nil))
                return
            }
            UIPasteboard.general.image = image
            result(true)
            
        case "paste":
            let text = UIPasteboard.general.string ?? ""
            result(["text": text])
            
        case "pasteRichText":
            let text = UIPasteboard.general.string ?? ""
            let html = UIPasteboard.general.value(forPasteboardType: "public.html") as? String
            let imageBytes = getImageBytesFromClipboard()
            result([
                "text": text,
                "html": html ?? NSNull(),
                "imageBytes": imageBytes ?? NSNull(),
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
            ])
            
        case "pasteImage":
            let imageBytes = getImageBytesFromClipboard()
            if let bytes = imageBytes {
                result(["imageBytes": bytes])
            } else {
                result(["imageBytes": NSNull()])
            }
            
        case "getContentType":
            let text = UIPasteboard.general.string ?? ""
            let html = UIPasteboard.general.value(forPasteboardType: "public.html") as? String
            let hasImage = UIPasteboard.general.image != nil
            
            if hasImage && (!text.isEmpty || (html != nil && !html!.isEmpty)) {
                result("mixed")
            } else if hasImage {
                result("image")
            } else if text.isEmpty && (html == nil || html!.isEmpty) {
                result("empty")
            } else if !text.isEmpty && html != nil && !html!.isEmpty {
                result("mixed")
            } else if html != nil && !html!.isEmpty {
                result("html")
            } else {
                result("text")
            }
            
        case "hasData":
            let text = UIPasteboard.general.string ?? ""
            result(!text.isEmpty)
            
        case "clear":
            UIPasteboard.general.string = ""
            result(true)
            
        case "getDataSize":
            let text = UIPasteboard.general.string ?? ""
            result(text.count)
            
        case "startMonitoring":
            startMonitoring()
            result(true)
            
        case "stopMonitoring":
            stopMonitoring()
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startMonitoring() {
        if clipboardChangeObserver != nil {
            return
        }
        
        // iOS doesn't have native clipboard change notifications
        // We'll use a timer-based approach as fallback
        // The Dart side will handle the actual polling
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkClipboardChange()
        }
    }
    
    private func stopMonitoring() {
        if let observer = clipboardChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            clipboardChangeObserver = nil
        }
    }
    
    private func checkClipboardChange() {
        let text = UIPasteboard.general.string ?? ""
        let html = UIPasteboard.general.value(forPasteboardType: "public.html") as? String
        
        eventSink?([
            "text": text,
            "html": html ?? NSNull(),
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ])
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startMonitoring()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopMonitoring()
        return nil
    }
    
    private func getImageBytesFromClipboard() -> [Int]? {
        guard let image = UIPasteboard.general.image else {
            return nil
        }
        guard let imageData = image.pngData() else {
            return nil
        }
        return Array(imageData.map { Int($0) })
    }
    
    deinit {
        stopMonitoring()
    }
}

