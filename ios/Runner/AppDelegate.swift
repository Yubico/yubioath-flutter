import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let managementManager = ManagementManager()

  override func applicationWillTerminate(_ application: UIApplication) {
    let manager = managementManager
    Task { await manager.stop() }
    super.applicationWillTerminate(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ManagementManager")!
    managementManager.register(with: registrar.messenger())
  }
}
