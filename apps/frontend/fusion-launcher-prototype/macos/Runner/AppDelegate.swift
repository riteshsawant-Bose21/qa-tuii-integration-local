import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  var flutterChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow, let controller = window.contentViewController as? FlutterViewController {
      flutterChannel = FlutterMethodChannel(name: "custom_url_scheme_channel", binaryMessenger: controller.engine.binaryMessenger)
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    if let url = urls.first {
      print("Received URL: \(url.absoluteString)")
      flutterChannel?.invokeMethod("onCustomUrlScheme", arguments: url.absoluteString)
    }
  }
}