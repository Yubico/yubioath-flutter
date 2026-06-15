import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[AppDelegate] didFinishLaunchingWithOptions")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Strong references to the per-app managers; without these the
  /// background USB monitor task in `ManagementManager` would be released.
  private var managementManager: ManagementManager?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    NSLog("[AppDelegate] didInitializeImplicitFlutterEngine — registering channels")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Legacy placeholder channel used by the iOS bring-up UI in main.dart.
    // Remove once the placeholder is replaced by `lib/ios/init.dart`.
    let yubikitRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "YubiKitChannel")!
    YubiKitChannel.register(with: yubikitRegistrar.messenger())

    // Per-application managers (Tier 1: Management only).
    let managementRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManagementManager")!
    managementManager = ManagementManager.register(with: managementRegistrar.messenger())

    NSLog("[AppDelegate] channels registered")
  }
}
