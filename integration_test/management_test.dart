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

  group('Toggle Applications on key', () {
    appTest('Toggle OTP', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbOtpKey = _getCapabilityWidgetKey(true, 'OTP');
      var otpChip = await _getCapabilityWidget(usbOtpKey);
      if (otpChip != null) {
        // we expect OTP to be enabled on the Key for this test
        expect(otpChip.selected, equals(true));
        await tester.tap(find.byKey(usbOtpKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.shortWait();
      }
      await tester.openManagementScreen();
      if (otpChip != null) {
        await tester.tap(find.byKey(usbOtpKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });
    appTest('Toggle PIV', (WidgetTester tester) async {
      await tester.openManagementScreen();
      var usbPivKey = _getCapabilityWidgetKey(true, 'PIV');
      var pivChip = await _getCapabilityWidget(usbPivKey);

      // find USB OTP capability
      if (pivChip != null) {
        expect(pivChip.selected, equals(true));
        await tester.tap(find.byKey(usbPivKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.shortWait();
      }
      await tester.openManagementScreen();
      if (pivChip != null) {
        // we expect OTP to be enabled on the Key for this test
        await tester.tap(find.byKey(usbPivKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });

    appTest('Toggle OATH', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbOathKey = _getCapabilityWidgetKey(true, 'OATH');
      var oathChip = await _getCapabilityWidget(usbOathKey);
      if (oathChip != null) {
        // we expect OTP to be enabled on the Key for this test
        expect(oathChip.selected, equals(true));
        await tester.tap(find.byKey(usbOathKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.shortWait();
      }
      await tester.openManagementScreen();
      if (oathChip != null) {
        await tester.tap(find.byKey(usbOathKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });
    appTest('Toggle OpenPGP', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbPgpKey = _getCapabilityWidgetKey(true, 'OpenPGP');
      var pgpChip = await _getCapabilityWidget(usbPgpKey);
      if (pgpChip != null) {
        // we expect OTP to be enabled on the Key for this test
        expect(pgpChip.selected, equals(true));
        await tester.tap(find.byKey(usbPgpKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.shortWait();
      }
      await tester.openManagementScreen();
      if (pgpChip != null) {
        await tester.tap(find.byKey(usbPgpKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });
    appTest('Toggle YubiHSM Auth', (WidgetTester tester) async {
      await tester.openManagementScreen();

      // find USB OTP capability
      var usbHsmKey = _getCapabilityWidgetKey(true, 'YubiHSM Auth');
      var hsmChip = await _getCapabilityWidget(usbHsmKey);
      if (hsmChip != null) {
        // we expect OTP to be enabled on the Key for this test
        expect(hsmChip.selected, equals(true));
        await tester.tap(find.byKey(usbHsmKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.shortWait();
      }
      await tester.openManagementScreen();
      if (hsmChip != null) {
        await tester.tap(find.byKey(usbHsmKey));
        await tester.shortWait();
        await tester.tap(find.byKey(management_keys.saveButtonKey));
        // long wait
        await tester.ultraLongWait();

        // no management screen visible now
        expect(find.byKey(management_keys.screenKey), findsNothing);
        await tester.longWait();
      }
    });
  });
  appTest('Toggle FIDO U2F', (WidgetTester tester) async {
    await tester.openManagementScreen();

    // find USB OTP capability
    var usbU2fKey = _getCapabilityWidgetKey(true, 'FIDO U2F');
    var u2fChip = await _getCapabilityWidget(usbU2fKey);
    if (u2fChip != null) {
      // we expect OTP to be enabled on the Key for this test
      expect(u2fChip.selected, equals(true));
      await tester.tap(find.byKey(usbU2fKey));
      await tester.shortWait();
      await tester.tap(find.byKey(management_keys.saveButtonKey));
      // long wait
      await tester.ultraLongWait();
      expect(find.byKey(management_keys.screenKey), findsNothing);
      await tester.shortWait();
    }
    await tester.openManagementScreen();
    if (u2fChip != null) {
      await tester.tap(find.byKey(usbU2fKey));
      await tester.shortWait();
      await tester.tap(find.byKey(management_keys.saveButtonKey));
      // long wait
      await tester.ultraLongWait();

      // no management screen visible now
      expect(find.byKey(management_keys.screenKey), findsNothing);
      await tester.longWait();
    }
  });
  appTest('Toggle FIDO2', (WidgetTester tester) async {
    await tester.openManagementScreen();

    // find USB OTP capability
    var usbFido2Key = _getCapabilityWidgetKey(true, 'FIDO2');
    var fido2Chip = await _getCapabilityWidget(usbFido2Key);
    if (fido2Chip != null) {
      // we expect OTP to be enabled on the Key for this test
      expect(fido2Chip.selected, equals(true));
      await tester.tap(find.byKey(usbFido2Key));
      await tester.shortWait();
      await tester.tap(find.byKey(management_keys.saveButtonKey));
      // long wait
      await tester.ultraLongWait();
      expect(find.byKey(management_keys.screenKey), findsNothing);
      await tester.shortWait();
    }
    await tester.openManagementScreen();
    if (fido2Chip != null) {
      await tester.tap(find.byKey(usbFido2Key));
      await tester.shortWait();
      await tester.tap(find.byKey(management_keys.saveButtonKey));
      // long wait
      await tester.ultraLongWait();

      // no management screen visible now
      expect(find.byKey(management_keys.screenKey), findsNothing);
      await tester.longWait();
    }
  });
}
