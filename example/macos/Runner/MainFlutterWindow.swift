import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Register the clipboard plugin
    ClipboardPlugin.register(with: flutterViewController.registrar(forPlugin: "ClipboardPlugin"))

    super.awakeFromNib()
  }
}
