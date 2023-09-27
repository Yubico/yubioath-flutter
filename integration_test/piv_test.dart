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
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/piv/keys.dart';
import 'package:yubico_authenticator/widgets/tooltip_if_truncated.dart';

import 'utils/test_util.dart';

// Future<void> resetPiv(WidgetTester tester) async {
//   // 1. open PIV view
//   var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
//   await tester.tap(pivDrawerButton);
//   await tester.pump(const Duration(milliseconds: 500));
//   // 1.3. Reset PIV
//   // 1. Click Configure JubiKey
//   await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());
//   await tester.pump(const Duration(milliseconds: 500));
//   // 2. Click Reset PIV
//   await tester.tap(find.byKey(resetAction).hitTestable());
//   await tester.pump(const Duration(milliseconds: 2000));
//   // 3. Click Reset
//   await tester.tap(find.byKey(resetButton).hitTestable());
//   await tester.pump(const Duration(milliseconds: 2000));
//   // 4. Verify Resetedness
//   expect(find.byWidgetPredicate((widget) {
//     if (widget is AppListItem) {
//       final AppListItem textWidget = widget;
//       if ((textWidget.key == appListItem9a ||
//               textWidget.key == appListItem9c ||
//               textWidget.key == appListItem9d ||
//               textWidget.key == appListItem9e) &&
//           textWidget.subtitle == 'No certificate loaded') {
//         return true;
//       }
//     }
//     return false;
//   }), findsNWidgets(4));
// }

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('PIV Settings', skip: isAndroid, () {
    appTest('Lock PIN, unlock with PUK', (WidgetTester tester) async {});
    appTest('Lock PUK, factory reset', (WidgetTester tester) async {});
    appTest('Change PIN', (WidgetTester tester) async {});
    appTest('Change PUK', (WidgetTester tester) async {});
    appTest('Change Management Key', (WidgetTester tester) async {});
    appTest('Lock Management Key with PIN', (WidgetTester tester) async {});
    appTest('Reset PIV', (WidgetTester tester) async {
      await tester.resetPiv();
    });
  });

  ///   Distinguished name schema according to RFC 4514
  ///   https://www.ietf.org/rfc/rfc4514.txt
  ///      CN      commonName (2.5.4.3)
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
    appTest('Generate 9a', (WidgetTester tester) async {
      await tester.resetPiv();
    });
    appTest('Generate 9a', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.pump(const Duration(milliseconds: 500));
      // 2. click meatball menu for 9a
      await tester.tap(find.byKey(meatballButton9a).hitTestable());
      await tester.pump(const Duration(milliseconds: 500));
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.pump(const Duration(milliseconds: 500));
      // 4. enter PIN and click Unlock
      await tester.enterText(
          find.byKey(managementKeyField).hitTestable(), '123456');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(unlockButton).hitTestable());
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Enter CN=apa
      await tester.enterText(
          find.byKey(subjectField).hitTestable(), 'CN=foobar');
      await tester.pump(const Duration(milliseconds: 500));

      // 6. Change algorithm
      // 7. set date
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.pump(const Duration(milliseconds: 2000));
      // 9 Verify Subject, verify Date
      expect(find.byWidgetPredicate((widget) {
        if (widget is TooltipIfTruncated) {
          final TooltipIfTruncated textWidget = widget;
          if (textWidget.key == certInfoSubjectKey &&
              textWidget.text == 'CN=foobar') {
            return true;
          }
        }
        return false;
      }), findsOneWidget);

      // 10. Click Delete Certificate
      // 11. Click Delete
      // 12. Click Close
      // 13 Verify subtitle 9a "Key without certificate loaded"

      await tester.pump(const Duration(milliseconds: 5000));
      //  Subject:
      //  RSA1024
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9c', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9d', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9e', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Load Certificate from file', (WidgetTester tester) async {});
    appTest('Export Certificate to file', (WidgetTester tester) async {});
    appTest('Delete Certificate', (WidgetTester tester) async {});
    appTest('Generate a CSR', (WidgetTester tester) async {});
  });
}
