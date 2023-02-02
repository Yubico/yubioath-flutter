import Cocoa
import FlutterMacOS

public class PlatformUtilPlugin: NSObject, FlutterPlugin {

    private var _mainWindow: NSWindow?
    public var mainWindow: NSWindow {
        get {
            return _mainWindow!
        }
        set {
            _mainWindow = newValue
        }
    }

    private var _registrar: FlutterPluginRegistrar!;

    public init(_ registrar: FlutterPluginRegistrar) {
        super.init()
        self._registrar = registrar
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "platform_util", binaryMessenger: registrar.messenger)
        let instance = PlatformUtilPlugin(registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        //let args: [String: Any] = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "init":
            print("initialization");
            mainWindow = (self._registrar.view?.window)!
            result(true)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
