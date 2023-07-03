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
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/management/views/keys.dart'
    as management_keys;

import 'utils/test_util.dart';

Key _getCapabilityWidgetKey(bool isUsb, String name) =>
    Key('management.keys.capability.${isUsb ? 'usb' : 'nfc'}.$name');

Future<FilterChip?> _getCapabilityWidget(Key key) async {
  return find.byKey(key).hitTestable().evaluate().single.widget as FilterChip;
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Management UI tests', () {
    appTest('Drawer items exist', (WidgetTester tester) async {
      await tester.openDrawer();
      expect(find.byKey(app_keys.managementAppDrawer).hitTestable(),
          findsOneWidget);
    });
  });

  group('Change OTP', () {
    appTest('Disable OTP', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbOtpKey = _getCapabilityWidgetKey(true, 'OTP');
      var otpChip = await _getCapabilityWidget(usbOtpKey);
      if (otpChip != null) {
        // we expect OTP to be enabled on the Key for this test
        expect(otpChip.selected, equals(true));
        await tester.tap(find.byKey(usbOtpKey));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.pump(const Duration(milliseconds: 2500));

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });

    appTest('Enable OTP', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbOtpKey = _getCapabilityWidgetKey(true, 'OTP');
      var otpChip = await _getCapabilityWidget(usbOtpKey);
      if (otpChip != null) {
        expect(otpChip.selected, equals(false));
        await tester.tap(find.byKey(usbOtpKey));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.pump(const Duration(milliseconds: 2500));

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });
  });
}
