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

import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/android/init.dart';
import 'package:yubico_authenticator/android/keys.dart' as android_keys;
import 'package:yubico_authenticator/android/qr_scanner/qr_scanner_view.dart';
import 'package:yubico_authenticator/app/views/device_avatar.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;

import '../test_util.dart';

Future<void> startUp(WidgetTester tester,
    [Map<dynamic, dynamic> startUpParams = const {}]) async {
  await tester.pumpWidget(await initialize());

  // only wait for yubikey connection when needed
  // needs_yubikey defaults to true
  if (startUpParams['needs_yubikey'] != false) {
    await tester.openDrawer();
    // wait for a YubiKey connection
    await tester.waitForFinder(find.descendant(
        of: find.byKey(app_keys.deviceInfoListTile),
        matching: find.byWidgetPredicate((widget) =>
            widget is DeviceAvatar && widget.key != app_keys.noDeviceAvatar)));
  }

  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> grantCameraPermissions(WidgetTester tester) async {
  await tester.waitForFinder(find.byType(QrScannerView));

  await tester.longWait();

  /// on android a QR Scanner starts
  /// we want to do a manual addition
  var manualEntryBtn = find.byKey(android_keys.manualEntryButton).hitTestable();

  if (manualEntryBtn.evaluate().isEmpty) {
    tester.testLog(true, 'Allow camera permission');
    manualEntryBtn = await tester.waitForFinder(manualEntryBtn);
  }

  await tester.tap(manualEntryBtn);
  await tester.longWait();
}
