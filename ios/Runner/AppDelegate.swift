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
  private var fidoManager: FidoManager?
  private var oathManager: OathManager?
  private var pivManager: PivManager?
  private var otpManager: OtpManager?
  private var qrScanner: QrScanner?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    NSLog("[AppDelegate] didInitializeImplicitFlutterEngine — registering channels")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let qrRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "QrScanner")!
    qrScanner = QrScanner(messenger: qrRegistrar.messenger())

    let managementRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManagementManager")!
    managementManager = ManagementManager.register(with: managementRegistrar.messenger())
    let fidoRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "FidoManager")!
    if let managementManager {
      fidoManager = FidoManager.register(
        with: fidoRegistrar.messenger(),
        managementManager: managementManager
      )
      let oathRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "OathManager")!
      oathManager = OathManager.register(
        with: oathRegistrar.messenger(),
        managementManager: managementManager
      )
      let pivRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "PivManager")!
      pivManager = PivManager.register(
        with: pivRegistrar.messenger(),
        managementManager: managementManager
      )
      let otpRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "OtpManager")!
      otpManager = OtpManager.register(
        with: otpRegistrar.messenger(),
        managementManager: managementManager
      )
    }

    NSLog("[AppDelegate] channels registered")
  }
}
