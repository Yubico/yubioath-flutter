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

@Tags(['android', 'desktop', 'oath'])
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/fido/keys.dart';

import 'utils/passkey_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Passkey PIN tests', () {
    const simplePin = '1111';
    const fidoPin1 = '947344';
    const fidoPin2 = '478178';

    /// Sadly these tests are built on each other to save reset-dance

    appTest('Reset Fido2 1/3', (WidgetTester tester) async {
      await tester.resetFido2();
    });
    group('Set/change pin', (){
      appTest('Set simplePin', (WidgetTester tester) async {
        // OBS: This will not work if there is pin complexity requirements
        await tester.configurePasskey();

        await tester.tap(find.byKey(managePinAction).hitTestable());
        await tester.shortWait();

        await tester.enterText(find.byKey(newPin), simplePin);
        await tester.shortWait();
        await tester.enterText(find.byKey(confirmPin), simplePin);
        await tester.shortWait();

        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.shortWait();

        /// TODO: deal with error messages from fips keys

        /// TODO: make sure that the outcome of this test is a set state, right now it differs between FIPS and non-FIPS keys.

      });
      appTest('Change to fidoPin1', (WidgetTester tester) async {
        await tester.configurePasskey();

        await tester.tap(find.byKey(managePinAction).hitTestable());
        await tester.shortWait();

        await tester.enterText(find.byKey(currentPin), simplePin);
        await tester.shortWait();
        await tester.enterText(find.byKey(newPin), fidoPin1);
        await tester.shortWait();
        await tester.enterText(find.byKey(confirmPin), fidoPin1);
        await tester.shortWait();

        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.shortWait();
      });
      appTest('Change to fidoPin2', (WidgetTester tester) async {
        await tester.configurePasskey();

        await tester.tap(find.byKey(managePinAction));
        await tester.shortWait();

        await tester.enterText(find.byKey(currentPin), fidoPin1);
        await tester.shortWait();
        await tester.enterText(find.byKey(newPin), fidoPin2);
        await tester.shortWait();
        await tester.enterText(find.byKey(confirmPin), fidoPin2);
        await tester.shortWait();

        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.shortWait();
      });
    });
    appTest('Reset Fido2 2/3', (WidgetTester tester) async {
      await tester.resetFido2();
    });
    group('Pin use, pin lock', () {
      appTest('Set fidoPin1 and unlock passkey app with pin', (WidgetTester tester) async {
        await tester.configurePasskey();

        //set pin
        await tester.tap(find.byKey(managePinAction).hitTestable());
        await tester.shortWait();

        await tester.enterText(find.byKey(newPin), fidoPin1);
        await tester.shortWait();
        await tester.enterText(find.byKey(confirmPin), fidoPin1);
        await tester.shortWait();
        await tester.tap(find.byKey(saveButton).hitTestable());
        await tester.shortWait();

        // re-focus passkey app
        await tester.tap(find.byKey(otpAppDrawer).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(fidoPasskeysAppDrawer).hitTestable());
        await tester.shortWait();

        // unlock with pin
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), fidoPin1);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
      });

      appTest('Wrong pin 1/3', (WidgetTester tester) async {
        await tester.tap(find.byKey(fidoPasskeysAppDrawer).hitTestable());
        await tester.shortWait();

        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();

        /// TODO verify that l_pin_soft_locked is seen.
      });

      appTest('Wrong pin 2/3', (WidgetTester tester) async {
        await tester.tap(find.byKey(fidoPasskeysAppDrawer).hitTestable());
        await tester.shortWait();

        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();

        /// TODO verify that l_pin_soft_locked is seen.
      });

      appTest('Wrong pin 3/3', (WidgetTester tester) async {
        await tester.tap(find.byKey(fidoPasskeysAppDrawer).hitTestable());
        await tester.shortWait();

        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();
        await tester.tap(find.byKey(pinEntry).hitTestable());
        await tester.shortWait();
        await tester.enterText(find.byKey(pinEntry), simplePin);
        await tester.shortWait();
        await tester.tap(find.byKey(unlockFido2WithPin).hitTestable());
        await tester.shortWait();


        /// TODO verify that l_pin_blocked_reset_locked is seen.
      });
    });
    appTest('Reset Fido2 3/3', (WidgetTester tester) async {
      await tester.resetFido2();
    });
  });
}
