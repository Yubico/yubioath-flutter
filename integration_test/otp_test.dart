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

@Tags(['desktop', 'otp'])
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/otp/keys.dart';
import 'package:yubico_authenticator/otp/models.dart';

import 'utils/otp_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OTP UI tests', () {
    appTest('Yubico OTP slot 1', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      //verify "Slot 1 is empty"
      await tester.openSlotMenu(SlotId.one);

      await tester.tap(find.byKey(configureYubiOtp).hitTestable());
      await tester.shortWait();

      // this generates all the fields and saves yubiotp
      await tester.tap(find.byKey(useSerial).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(generatePrivateId).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(generateSecretKey).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.shortWait();

      //verify "Slot 1 is configured"
    });

    appTest('Challenge-Response slot 1', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is configured"

      await tester.openSlotMenu(SlotId.one);

      await tester.tap(find.byKey(configureChalResp).hitTestable());
      await tester.shortWait();

      // this generates and saves chall-resp
      await tester.tap(find.byKey(generateSecretKey).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is configured"
    });

    appTest('Static Password slot 2', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      // verify "Slot 2 is empty"

      await tester.openSlotMenu(SlotId.two);

      await tester.tap(find.byKey(configureStatic).hitTestable());
      await tester.shortWait();

      // this generates and saves static password
      await tester.tap(find.byKey(generateSecretKey).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.shortWait();

      // verify "Slot 2 is configured"
    });

    appTest('OATH-HOTP slot 2', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      // verify "Slot 2 is configured"

      await tester.openSlotMenu(SlotId.two);

      await tester.tap(find.byKey(configureHotp).hitTestable());
      await tester.shortWait();

      // this writes and saves oath secret
      await tester.enterText(find.byKey(secretField), 'asdfasdf');
      await tester.shortWait();
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.shortWait();

      // verify "Slot 2 is configured"
    });

    appTest('Swap slots', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is configured"
      // verify "Slot 2 is configured"

      // taps swap
      await tester.tapSwapSlotsButton();
      await tester.tap(find.byKey(swapButton).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is configured"
      // verify "Slot 2 is configured"
    });

    appTest('Delete Credentials', (WidgetTester tester) async {
      await tester.tap(find.byKey(otpAppDrawer).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is configured"
      // verify "Slot 2 is configured"

      await tester.openSlotMenu(SlotId.one);
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());

      // wait for any toasts to be gone
      await tester.pump(const Duration(seconds: 3));
      var closeFinder = find.byKey(closeButton);
      if (closeFinder.evaluate().isNotEmpty) {
        // close the view
        await tester.tap(closeFinder);
        await tester.shortWait();
      }

      // we need to right click on slot 2
      await tester.openSlotMenu(SlotId.two);
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.shortWait();

      // verify "Slot 1 is empty"
      // verify "Slot 2 is empty"
    });
  });
}
