/*
 * Copyright (C) 2023 Yubico.
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

@Tags(['desktop', 'management'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/management/views/keys.dart';

import 'utils/test_util.dart';

// Key _getCapabilityWidgetKey(bool isUsb, String name) =>
//     Key('management.keys.capability.${isUsb ? 'usb' : 'nfc'}.$name');
//
// Future<FilterChip?> _getCapabilityWidget(Key key) async {
//   return find.byKey(key).hitTestable().evaluate().single.widget as FilterChip;
// }

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Toggle Applications on key', () {
    appTest('Toggle all but PIV 1', (WidgetTester tester) async {
      await tester.openHomeAndToggleScreen();
      await tester.shortWait();
      await tester.tap(find.text('Yubico OTP').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('OATH').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('OpenPGP').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('YubiHSM Auth').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('FIDO U2F').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('FIDO2').hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(saveButtonKey).hitTestable());
      await tester.longWait();
    });
    appTest('Toggle all but PIV 2', (WidgetTester tester) async {
      await tester.openHomeAndToggleScreen();
      await tester.shortWait();
      await tester.tap(find.text('Yubico OTP').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('OATH').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('OpenPGP').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('YubiHSM Auth').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('FIDO U2F').hitTestable());
      await tester.shortWait();
      await tester.tap(find.text('FIDO2').hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(saveButtonKey).hitTestable());
      await tester.longWait();
    });
  });

  //   group('OLD: Toggle Applications on key', () {
  //   appTest('Toggle OTP', (WidgetTester tester) async {
  //     await tester.openHomeAndToggleScreen();
  //     await tester.shortWait();
  //     await tester.tap(find.text('Yubico OTP').hitTestable());
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(saveButtonKey).hitTestable());
  //     await tester.ultraLongWait();
  //
  //     // TODO: expecter that the Yubico OTP is not present
  //
  //     await tester.openHomeAndToggleScreen();
  //     await tester.shortWait();
  //     await tester.tap(find.text('Yubico OTP').hitTestable());
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(saveButtonKey).hitTestable());
  //     await tester.ultraLongWait();
  //
  //     // TODO: this is old method of doing this test, review if usable.
  //     // find USB OTP capability
  //     // var usbOtpKey = _getCapabilityWidgetKey(true, 'Yubico OTP');
  //     // var otpChip = await _getCapabilityWidget(usbOtpKey);
  //     // if (otpChip != null) {
  //     //   // we expect OTP to be enabled on the Key for this test
  //     //   expect(otpChip.selected, equals(true));
  //     //   await tester.tap(find.byKey(usbOtpKey));
  //     //   await tester.shortWait();
  //     //   await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     //   // long wait
  //     //   await tester.ultraLongWait();
  //     //   expect(find.byKey(management_keys.screenKey), findsNothing);
  //     //   await tester.shortWait();
  //     // }
  //     // await tester.openToggleScreen();
  //     // if (otpChip != null) {
  //     //   await tester.tap(find.byKey(usbOtpKey));
  //     //   await tester.shortWait();
  //     //   await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     //   // long wait
  //     //   await tester.ultraLongWait();
  //     //
  //     //   // no management screen visible now
  //     //   expect(find.byKey(management_keys.screenKey), findsNothing);
  //     //   await tester.longWait();
  //     // }
  //   });
  //   appTest('Toggle PIV', (WidgetTester tester) async {
  //     await tester.openToggleScreen();
  //     var usbPivKey = _getCapabilityWidgetKey(true, 'PIV');
  //     var pivChip = await _getCapabilityWidget(usbPivKey);
  //
  //     // find USB PIV capability
  //     if (pivChip != null) {
  //       expect(pivChip.selected, equals(true));
  //       await tester.tap(find.byKey(usbPivKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.shortWait();
  //     }
  //     await tester.openToggleScreen();
  //     if (pivChip != null) {
  //       // we expect PIV to be enabled on the Key for this test
  //       await tester.tap(find.byKey(usbPivKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //
  //       // no management screen visible now
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.longWait();
  //     }
  //   });
  //
  //   appTest('Toggle OATH', (WidgetTester tester) async {
  //     await tester.openToggleScreen();
  //
  //     // find USB OATH capability
  //     var usbOathKey = _getCapabilityWidgetKey(true, 'OATH');
  //     var oathChip = await _getCapabilityWidget(usbOathKey);
  //     if (oathChip != null) {
  //       // we expect OATH to be enabled on the Key for this test
  //       expect(oathChip.selected, equals(true));
  //       await tester.tap(find.byKey(usbOathKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.shortWait();
  //     }
  //     await tester.openToggleScreen();
  //     if (oathChip != null) {
  //       await tester.tap(find.byKey(usbOathKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //
  //       // no management screen visible now
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.longWait();
  //     }
  //   });
  //   appTest('Toggle OpenPGP', (WidgetTester tester) async {
  //     await tester.openToggleScreen();
  //
  //     // find USB OPENPGP capability
  //     var usbPgpKey = _getCapabilityWidgetKey(true, 'OpenPGP');
  //     var pgpChip = await _getCapabilityWidget(usbPgpKey);
  //     if (pgpChip != null) {
  //       // we expect OPENPGP to be enabled on the Key for this test
  //       expect(pgpChip.selected, equals(true));
  //       await tester.tap(find.byKey(usbPgpKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.shortWait();
  //     }
  //     await tester.openToggleScreen();
  //     if (pgpChip != null) {
  //       await tester.tap(find.byKey(usbPgpKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //
  //       // no management screen visible now
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.longWait();
  //     }
  //   });
  //   appTest('Toggle YubiHSM Auth', (WidgetTester tester) async {
  //     await tester.openToggleScreen();
  //
  //     // find USB YubiHSM Auth capability
  //     var usbHsmKey = _getCapabilityWidgetKey(true, 'YubiHSM Auth');
  //     var hsmChip = await _getCapabilityWidget(usbHsmKey);
  //     if (hsmChip != null) {
  //       // we expect YubiHSM Auth to be enabled on the Key for this test
  //       expect(hsmChip.selected, equals(true));
  //       await tester.tap(find.byKey(usbHsmKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.shortWait();
  //     }
  //     await tester.openToggleScreen();
  //     if (hsmChip != null) {
  //       await tester.tap(find.byKey(usbHsmKey));
  //       await tester.shortWait();
  //       await tester.tap(find.byKey(management_keys.saveButtonKey));
  //       // long wait
  //       await tester.ultraLongWait();
  //
  //       // no management screen visible now
  //       expect(find.byKey(management_keys.screenKey), findsNothing);
  //       await tester.longWait();
  //     }
  //   });
  // });
  // appTest('Toggle FIDO U2F', (WidgetTester tester) async {
  //   await tester.openToggleScreen();
  //
  //   // find USB FIDO U2F capability
  //   var usbU2fKey = _getCapabilityWidgetKey(true, 'FIDO U2F');
  //   var u2fChip = await _getCapabilityWidget(usbU2fKey);
  //   if (u2fChip != null) {
  //     // we expect FIDO U2F to be enabled on the Key for this test
  //     expect(u2fChip.selected, equals(true));
  //     await tester.tap(find.byKey(usbU2fKey));
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     // long wait
  //     await tester.ultraLongWait();
  //     expect(find.byKey(management_keys.screenKey), findsNothing);
  //     await tester.shortWait();
  //   }
  //   await tester.openToggleScreen();
  //   if (u2fChip != null) {
  //     await tester.tap(find.byKey(usbU2fKey));
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     // long wait
  //     await tester.ultraLongWait();
  //
  //     // no management screen visible now
  //     expect(find.byKey(management_keys.screenKey), findsNothing);
  //     await tester.longWait();
  //   }
  // });
  // appTest('Toggle FIDO2', (WidgetTester tester) async {
  //   await tester.openToggleScreen();
  //
  //   // find USB FIDO2 capability
  //   var usbFido2Key = _getCapabilityWidgetKey(true, 'FIDO2');
  //   var fido2Chip = await _getCapabilityWidget(usbFido2Key);
  //   if (fido2Chip != null) {
  //     // we expect FIDO2 to be enabled on the Key for this test
  //     expect(fido2Chip.selected, equals(true));
  //     await tester.tap(find.byKey(usbFido2Key));
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     // long wait
  //     await tester.ultraLongWait();
  //     expect(find.byKey(management_keys.screenKey), findsNothing);
  //     await tester.shortWait();
  //   }
  //   await tester.openToggleScreen();
  //   if (fido2Chip != null) {
  //     await tester.tap(find.byKey(usbFido2Key));
  //     await tester.shortWait();
  //     await tester.tap(find.byKey(management_keys.saveButtonKey));
  //     // long wait
  //     await tester.ultraLongWait();
  //
  //     // no management screen visible now
  //     expect(find.byKey(management_keys.screenKey), findsNothing);
  //     await tester.longWait();
  //   }
  // });
}
