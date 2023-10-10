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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qrscanner_zxing/qrscanner_zxing.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_platform_interface.dart';

class MockQRScannerZxingPlatform
    with MockPlatformInterfaceMixin
    implements QRScannerZxingPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> scanBitmap(Uint8List bitmap) =>
      Future.value(bitmap.length.toString());
}

void main() {
  final QRScannerZxingPlatform initialPlatform =
      QRScannerZxingPlatform.instance;

  test('$MethodChannelQRScannerZxing is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQRScannerZxing>());
  });

  test('getPlatformVersion', () async {
    QRScannerZxing qrscannerZxingPlugin = QRScannerZxing();
    MockQRScannerZxingPlatform fakePlatform = MockQRScannerZxingPlatform();
    QRScannerZxingPlatform.instance = fakePlatform;

    expect(await qrscannerZxingPlugin.getPlatformVersion(), '42');
  });

  test('scanBitmap', () async {
    QRScannerZxing qrscannerZxingPlugin = QRScannerZxing();
    MockQRScannerZxingPlatform fakePlatform = MockQRScannerZxingPlatform();
    QRScannerZxingPlatform.instance = fakePlatform;

    expect(await qrscannerZxingPlugin.scanBitmap(Uint8List(10)), '10');
  });
}
