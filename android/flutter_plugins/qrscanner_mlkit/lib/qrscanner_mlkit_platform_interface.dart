import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qrscanner_mlkit_method_channel.dart';

abstract class QRScannerMLKitPlatform extends PlatformInterface {
  /// Constructs a QRScannerMLKitPlatform.
  QRScannerMLKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static QRScannerMLKitPlatform _instance = MethodChannelQRScannerMLKit();

  /// The default instance of [QRScannerMLKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelQRScannerMLKit].
  static QRScannerMLKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QRScannerMLKitPlatform] when
  /// they register themselves.
  static set instance(QRScannerMLKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
