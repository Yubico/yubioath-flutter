import Flutter
import YubiKit

final class YubiKitChannel {
    static let channelName = "com.yubico.authenticator/yubikit"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        let handler = YubiKitChannel()
        channel.setMethodCallHandler { call, result in
            handler.handle(call: call, result: result)
        }
    }

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[YubiKitChannel] received call: \(call.method)")
        switch call.method {
        case "readSerial":
            let args = call.arguments as? [String: Any]
            let via = (args?["via"] as? String) ?? "nfc"
            Task {
                do {
                    let serial = try await readSerial(via: via)
                    NSLog("[YubiKitChannel] success: \(serial)")
                    await MainActor.run { result(serial) }
                } catch {
                    NSLog("[YubiKitChannel] error: \(error)")
                    await MainActor.run {
                        result(FlutterError(
                            code: "yubikit_error",
                            message: String(describing: error),
                            details: nil
                        ))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func readSerial(via: String) async throws -> String {
        switch via {
        case "usb":
            NSLog("[YubiKitChannel] starting USB connection…")
            let connection = try await WiredSmartCardConnection.makeConnection()
            NSLog("[YubiKitChannel] USB connection established")
            do {
                let session = try await ManagementSession.makeSession(connection: connection)
                let info = try await session.getDeviceInfo()
                let serialString = "\(info.serialNumber)"
                await connection.close(error: nil)
                return serialString
            } catch {
                await connection.close(error: error)
                throw error
            }
        default:
            NSLog("[YubiKitChannel] starting NFC connection…")
            let connection = try await NFCSmartCardConnection.makeConnection(
                alertMessage: "Hold your YubiKey near the top of the phone"
            )
            NSLog("[YubiKitChannel] NFC connection established")
            do {
                let session = try await ManagementSession.makeSession(connection: connection)
                let info = try await session.getDeviceInfo()
                let serialString = "\(info.serialNumber)"
                await connection.close(message: "Serial: \(serialString)")
                return serialString
            } catch {
                await connection.close(message: "Error: \(error)")
                throw error
            }
        }
    }
}

