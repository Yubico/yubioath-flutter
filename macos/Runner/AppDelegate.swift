import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running if window closes
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
      if let window = NSApp.windows.first {
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
      }

          // Add the method channel
      if let controller = NSApp.windows.first?.contentViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: "titlebar_channel", binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { (call, result) in
          if call.method == "getTitlebarHeight" {
            if let window = NSApp.windows.first {
              let contentViewHeight = window.contentView?.frame.height ?? 0
              let layoutRectHeight = window.contentLayoutRect.height
              let titlebarHeight = contentViewHeight - layoutRectHeight
              result(titlebarHeight)
            } else {
              result(FlutterError(code: "no_window", message: "Window not found", details: nil))
            }
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
      }

      super.applicationDidFinishLaunching(notification)
    }
}
