import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let managementManager = ManagementManager()
  private lazy var oathManager = OathManager(managementManager: managementManager)
  private let qrScanner = QrScanner()

  override func applicationWillTerminate(_ application: UIApplication) {
    let manager = managementManager
    Task { await manager.stop() }
    super.applicationWillTerminate(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManagementManager")!
    managementManager.register(with: registrar.messenger())
    let oathRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "OathManager")!
    oathManager.register(with: oathRegistrar.messenger())
    let qrRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "QrScanner")!
    qrScanner.register(with: qrRegistrar.messenger())
  }
}
