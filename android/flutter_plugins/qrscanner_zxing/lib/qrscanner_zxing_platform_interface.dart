import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qrscanner_zxing_method_channel.dart';

abstract class QRScannerZxingPlatform extends PlatformInterface {
  /// Constructs a QRScannerZxingPlatform.
  QRScannerZxingPlatform() : super(token: _token);

  static final Object _token = Object();

  static QRScannerZxingPlatform _instance = MethodChannelQRScannerZxing();

  /// The default instance of [QRScannerZxingPlatform] to use.
  ///
  /// Defaults to [MethodChannelQRScannerZxing].
  static QRScannerZxingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QRScannerZxingPlatform] when
  /// they register themselves.
  static set instance(QRScannerZxingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
