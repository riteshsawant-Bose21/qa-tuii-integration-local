import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var flutterChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup method channel for URL handling
    if let controller = window?.rootViewController as? FlutterViewController {
      flutterChannel = FlutterMethodChannel(name: "custom_url_scheme_channel", binaryMessenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL redirection
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    flutterChannel?.invokeMethod("onCustomUrlScheme", arguments: url.absoluteString)
    return true
  }
}