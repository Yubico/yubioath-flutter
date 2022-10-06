/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
