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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/piv/keys.dart';
// import 'package:yubico_authenticator/widgets/tooltip_if_truncated.dart';

import 'utils/piv_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('PIV Settings', skip: isAndroid, () {
    const factoryPin = '123456';
    const factoryPuk = '12345678';
    const factoryManagemenKey =
        '010203040506070801020304050607080102030405060708';
    appTest('Reset PIV (settings-init)', (WidgetTester tester) async {
      await tester.resetPiv();
      await tester.shortWait();
    });
    appTest('Lock PIN, unlock with PUK', (WidgetTester tester) async {
      await tester.configurePiv();
      await tester.shortWait();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.lockPinPuk();
      await tester.shortWait();
      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());

      /// TODO: This expect needs to verify that Pin underline is 'Blocked'
      /// expect(find.byKey(managePinAction), find.byTooltip('Blocked'));
      await tester.shortWait();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.enterText(find.byKey(pinPukField).hitTestable(), factoryPuk);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(newPinPukField).hitTestable(), factoryPin);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(confirmPinPukField).hitTestable(), factoryPin);
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.shortWait();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.longWait();
      await tester.resetPiv();
    });
    appTest('Lock PUK, lock PIN, factory reset', (WidgetTester tester) async {
      await tester.configurePiv();
      await tester.shortWait();
      await tester.tap(find.byKey(managePukAction).hitTestable());
      await tester.shortWait();
      await tester.lockPinPuk();
      await tester.shortWait();
      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());

      /// TODO: This expect needs to verify that PUK underline is 'Blocked'
      /// expect(find.byKey(managePukAction), find.byTooltip('Blocked'));

      await tester.shortWait();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.lockPinPuk();
      await tester.shortWait();
      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());

      /// TODO: This expect needs to verify that Pin underline is 'Blocked'
      /// expect(find.byKey(managePinAction), find.byTooltip('Blocked'));

      await tester.shortWait();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(managePukAction).hitTestable());
      await tester.shortWait();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.longWait();
      await tester.resetPiv();
    });
    appTest('Change PIN', (WidgetTester tester) async {
      const newpin = '123123';
      await tester.configurePiv();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.enterText(find.byKey(pinPukField).hitTestable(), factoryPin);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPinPukField).hitTestable(), newpin);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(confirmPinPukField).hitTestable(), newpin);
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      await tester.configurePiv();
      await tester.tap(find.byKey(managePinAction).hitTestable());
      await tester.shortWait();
      await tester.enterText(find.byKey(pinPukField).hitTestable(), newpin);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(newPinPukField).hitTestable(), factoryPin);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(confirmPinPukField).hitTestable(), factoryPin);
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
    });
    appTest('Change PUK', (WidgetTester tester) async {
      const newpuk = '12341234';
      await tester.configurePiv();
      await tester.tap(find.byKey(managePukAction).hitTestable());
      await tester.shortWait();
      await tester.enterText(find.byKey(pinPukField).hitTestable(), factoryPuk);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPinPukField).hitTestable(), newpuk);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(confirmPinPukField).hitTestable(), newpuk);
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      await tester.configurePiv();
      await tester.tap(find.byKey(managePukAction).hitTestable());
      await tester.shortWait();
      await tester.enterText(find.byKey(pinPukField).hitTestable(), newpuk);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(newPinPukField).hitTestable(), factoryPuk);
      await tester.shortWait();
      await tester.enterText(
          find.byKey(confirmPinPukField).hitTestable(), factoryPuk);
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
    });
    group('PIV Management Key', () {
      const newmanagementkey =
          'aaaabbbbccccaaaabbbbccccaaaabbbbccccaaaabbbbcccc';
      const boundsmanagementkey =
          'llllkkkkmmmmllllkkkkmmmmllllkkkkmmmmllllkkkkmmmm';
      const shortmanagementkey =
          'aaaabbbbccccaaaabbbbccccaaaabbbbccccaaaabbbbccc';

      appTest('Bad managementkey key', (WidgetTester tester) async {
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.longWait();
        // testing out of bounds management key does not work
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), boundsmanagementkey);
        await tester.longWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        // testing too short management key does not work
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), shortmanagementkey);
        await tester.longWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        // TODO: verify state
      });
      appTest('Change managementkey key', (WidgetTester tester) async {
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.shortWait();
        // setting newmanagementkey
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), newmanagementkey);
        await tester.longWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        // verifying newmanagementkey
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.shortWait();
        await tester.enterText(
            find.byKey(managementKeyField).hitTestable(), newmanagementkey);
        await tester.shortWait();
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), newmanagementkey);
        await tester.shortWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        await tester.resetPiv();
      });
      appTest('Change managementkey type', (WidgetTester tester) async {
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.shortWait();
        // TODO: this needs to use manageManagementKeyAction chip
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), newmanagementkey);
        await tester.shortWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();

        await tester.resetPiv();
        await tester.shortWait();
      });
      appTest('Change managementkey PIN-lock', (WidgetTester tester) async {
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.shortWait();
        // testing out of bounds management key does not work
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), newmanagementkey);
        await tester.shortWait();
        // TODO: Investigate why chip-tap fails
        //await tester.tap(find.byKey(pinLockManagementKeyChip).hitTestable());
        //await tester.shortWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        await tester.resetPiv();
        await tester.shortWait();
      });

      appTest('Random managementkeytype', (WidgetTester tester) async {
        await tester.configurePiv();
        await tester.shortWait();
        await tester.tap(find.byKey(manageManagementKeyAction).hitTestable());
        await tester.shortWait();
        // rndm 3x, for luck
        await tester.tap(find.byKey(managementKeyRefresh).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(managementKeyRefresh).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(managementKeyRefresh).hitTestable());
        await tester.shortWait();
        await tester.enterText(
            find.byKey(newPinPukField).hitTestable(), newmanagementkey);
        await tester.shortWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.longWait();
        await tester.resetPiv();
      });

      /// TODO: The rest of management key settings, when input fields are fixed
      appTest('Reset PIV (settings-exit)', (WidgetTester tester) async {
        await tester.resetPiv();
        await tester.shortWait();
      });
    });
  });

  //    Distinguished name schema according to RFC 4514
  //    https://www.ietf.org/rfc/rfc4514.txt
  //       CN      commonName (2.5.4.3)
  //       L       localityName (2.5.4.7)
  //       ST      stateOrProvinceName (2.5.4.8)
  //       O       organizationName (2.5.4.10)
  //       OU      organizationalUnitName (2.5.4.11)
  //       C       countryName (2.5.4.6)
  //       STREET  streetAddress (2.5.4.9)
  //       DC      domainComponent (0.9.2342.19200300.100.1.25)
  //       UID     userId (0.9.2342.19200300.100.1.1)
  //       Example: CN=cn,L=l,ST=st,O=o,OU=ou,C=c,STREET=street,DC=dc,DC=net,UID=uid

  group('PIV Certificate load', skip: isAndroid, () {
    appTest('Reset PIV (load-init)', (WidgetTester tester) async {
      await tester.resetPiv();
    });
    appTest('Generate 9a', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9a
      await tester.tap(find.byKey(meatballButton9a).hitTestable());
      await tester.longWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.longWait();
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=Generate9a');
      await tester.longWait();

      // 6. Change algorithm: RSA1024
      // 7. Date [unchanged]
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      // 9 Verify Subject, verify Date
/*      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=Generate9a') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);*/

      await tester.pump(const Duration(milliseconds: 5000));
      // 10. Export Certificate
      // await tester.tap(find.byKey(exportAction).hitTestable());
      // await tester.enterText(
      // find.byKey($$Save as$$).hitTestable(), 'Generate9a');
      // await tester.tap(find.byKey($$Save button$$).hitTestable());
      // await tester.longWait();
      // 11. Delete Certificate
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.longWait();
    });
    appTest('Generate 9c', (WidgetTester tester) async {
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9c
      await tester.tap(find.byKey(meatballButton9c).hitTestable());
      await tester.longWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.longWait();
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=Generate9c');
      await tester.longWait();

      // 6. Change algorithm: RSA2048
      // 7. set date
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      // 9 Verify Subject, verify Date
      //      TODO: this seems not to work!
/*      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=foobar') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);*/

      await tester.longWait();
      // 10. Delete Certificate
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.longWait();
    });
    appTest('Generate 9d', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9d
      await tester.tap(find.byKey(meatballButton9d).hitTestable());
      await tester.longWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.longWait();
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=Generate9d');
      await tester.longWait();

      // 6. Change algorithm: ECCP256
      // 7. Date [unchanged]
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      // 9 Verify Subject, verify Date
/*      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=Generate9d') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);*/

      await tester.longWait();
      // 10. Export Certificate
      // await tester.tap(find.byKey(exportAction).hitTestable());
      // await tester.enterText(
      // find.byKey($$Save as$$).hitTestable(), 'Generate9d');
      // await tester.tap(find.byKey($$Save button$$).hitTestable());
      // await tester.longWait();
      // 11. Delete Certificate
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.longWait();
    });
    appTest('Generate 9e', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9e
      await tester.tap(find.byKey(meatballButton9e).hitTestable());
      await tester.longWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.longWait();
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=Generate9e');
      await tester.longWait();

      // 6. Change algorithm: ECCP384
      // 7. Date [unchanged]
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      // 9 Verify Subject, verify Date
/*      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=Generate9e') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);*/

      await tester.longWait();
      // 10. Export Certificate
      // await tester.tap(find.byKey(exportAction).hitTestable());
      // await tester.enterText(
      // find.byKey($$Save as$$).hitTestable(), 'Generate9e');
      // await tester.tap(find.byKey($$Save button$$).hitTestable());
      // await tester.longWait();
      // 11. Delete Certificate
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.longWait();
    });
    // appTest('Import outdated Key+Certificate from file',
    //     (WidgetTester tester) async {
    //   /// TODO fileload needs to be handled
    //   // 1. open PIV view
    //   var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
    //   await tester.tap(pivDrawerButton);
    //   await tester.longWait();
    //   // 2. click meatball menu for 9c
    //   await tester.tap(find.byKey(meatballButton9c).hitTestable());
    //   await tester.longWait();
    //   // 3. click import
    //   await tester.tap(find.byKey(importAction).hitTestable());
    //   await tester.longWait();
    //   // 4. pick key: outdated_key.pem and "Choose"
    //   // 5. TODO: tap close
    //   // 6. Verify slot 9c "Key without certificate loaded"
    //   // 7. click meatball menu for 9c
    //   await tester.tap(find.byKey(meatballButton9c).hitTestable());
    //   await tester.longWait();
    //   // 8. click import
    //   await tester.tap(find.byKey(importAction).hitTestable());
    //   await tester.longWait();
    //   // 9. pick key: outdated_cert.pem and "Choose"
    //   // 10. Tap "Import" on 'Import File Dialogue'
    //   // Verify Certificate
    // });
    // appTest('Import neverexpire Key+Certificate from file',
    //     (WidgetTester tester) async {
    //   /// TODO fileload needs to be handled
    //   // // 1. open PIV view
    //   // var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
    //   // await tester.tap(pivDrawerButton);
    //   // await tester.longWait();
    //   // // 2. click meatball menu for 9d
    //   // await tester.tap(find.byKey(meatballButton9d).hitTestable());
    //   // await tester.longWait();
    //   // // 3. click import
    //   // await tester.tap(find.byKey(importAction).hitTestable());
    //   // await tester.longWait();
    //   // // 4. pick key: neverexpire_key.pem and "Choose"
    //   // // 5. TODO: tap close
    //   // // 6. Verify slot 9c "Key without certificate loaded"
    //   // // 7. click meatball menu for 9d
    //   // await tester.tap(find.byKey(meatballButton9d).hitTestable());
    //   // await tester.longWait();
    //   // // 8. click import
    //   // await tester.tap(find.byKey(importAction).hitTestable());
    //   // await tester.longWait();
    //   // // 9. pick key: neverexpire_cert.pem and "Choose"
    //   // // 10. Tap "Import" on 'Import File Dialogue'
    //   // // Verify Certificate
    // });
    appTest('Generate a CSR', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9e
      await tester.tap(find.byKey(meatballButton9e).hitTestable());
      await tester.longWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.longWait();
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=Generate9e-CSR');
      await tester.longWait();
      // 6. Change 'output format': CSR
      //      enum models.dart, generate_key_dialog.dart
      // 7. Choose File Name > Save As > 'File Name generate93-csr'
      //    TODO: where are files saved?
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      // 9 Verify 'No certificate loaded'
/*      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=Generate9e') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);*/
    });
    // appTest('Reset PIV (load-exit)', (WidgetTester tester) async {
    //   /// TODO: investigate why this reset randomly fails!
    //   await tester.resetPiv();
    //   await tester.shortWait();
    // });
  });
}
