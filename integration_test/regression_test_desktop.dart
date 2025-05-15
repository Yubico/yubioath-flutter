/*
 * Copyright (C) 2025 Yubico.
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

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
//import 'package:yubico_authenticator/oath/keys.dart';
import 'package:yubico_authenticator/piv/keys.dart';
// import 'package:yubico_authenticator/core/state.dart';

import 'utils/keyless_test_util.dart';
import 'utils/oath_test_util.dart';
import 'utils/piv_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Keyless tests', () {
    appTest('Switch to Home', (WidgetTester tester) async {
      /// change to OATH view
      await tester.tapAppDrawerButton(homeDrawer);
      await tester.shortWait();
    });
    appTestKeyless('changing themes', (WidgetTester tester) async {
      await tester.tap(find.byKey(settingDrawerIcon).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(themeModeSetting));
      await tester.shortWait();
      await tester.tap(
        find.byKey(themeModeOption(ThemeMode.light)).hitTestable(),
      );
      await tester.longWait();
      await tester.tap(find.byKey(themeModeSetting));
      await tester.shortWait();
      await tester.tap(
        find.byKey(themeModeOption(ThemeMode.dark)).hitTestable(),
      );
      await tester.longWait();
      await tester.tap(find.byKey(themeModeSetting));
      await tester.shortWait();
      await tester.tap(
        find.byKey(themeModeOption(ThemeMode.system)).hitTestable(),
      );
      await tester.longWait();
    });
    appTestKeyless('changing languages', (WidgetTester tester) async {
      await tester.tap(find.byKey(settingDrawerIcon).hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(languageSetting).hitTestable());
      await tester.shortWait();
      await tester.tap(find.bySemanticsLabel('French').hitTestable());
      await tester.shortWait();
      await tester.tap(find.byKey(languageSetting).hitTestable());
      await tester.shortWait();
      await tester.tap(find.bySemanticsLabel('Anglais').hitTestable());
      await tester.shortWait();
    });
  });
  group('OATH Tests', () {
    var testAccount = Account(
      issuer: 'OATH_issuer',
      name: 'OATH_name',
      secret: 'abbaabba',
    );
    appTest('reset OATH', (WidgetTester tester) async {
      /// reset OATH application
      await tester.resetOATH();
      await tester.longWait();
    });
    appTest('Switch to OATH', (WidgetTester tester) async {
      /// change to OATH view
      await tester.tapAppDrawerButton(oathAppDrawer);
      await tester.shortWait();
    });
    appTest('Create OATH Account', (WidgetTester tester) async {
      await tester.addAccount(testAccount);
      await tester.shortWait();
    });
    appTest('Delete OATH Account', (WidgetTester tester) async {
      await tester.deleteAccount(testAccount);
      await tester.shortWait();
    });
  });
  group('PIV Tests', () {
    appTest('reset PIV', (WidgetTester tester) async {
      await tester.resetPiv();
      await tester.longWait();
    });
    appTest('Switch to PIV', (WidgetTester tester) async {
      /// change to OATH view
      await tester.tapAppDrawerButton(pivAppDrawer);
      await tester.shortWait();
    });
    appTest('Generate certificate in 9e', (WidgetTester tester) async {
      // 1. open PIV view
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.shortWait();
      // 2. click meatball menu for 9e
      await tester.tap(find.byKey(appListItem9e).hitTestable());
      await tester.shortWait();
      // 3. click generate
      await tester.tap(find.byKey(generateAction).hitTestable());
      await tester.longWait();
      // 4. enter PIN and click Unlock
      // await tester.enterText(
      //     find.byKey(managementKeyField).hitTestable(), '123456');
      // await tester.longWait();
      // await tester.tap(find.byKey(unlockButton).hitTestable());
      // await tester.longWait();

      // 5. Enter DN
      await tester.enterText(
        find.byKey(subjectField).hitTestable(),
        'CN=Generate9e',
      );
      await tester.shortWait();

      // 6. Change algorithm: ECCP384
      // 7. Date [unchanged]
      // 8. click save
      await tester.tap(find.byKey(saveButton).hitTestable());
      await tester.longWait();
      await tester.longWait();
    });
    appTest('Generate certificate in 9e', (WidgetTester tester) async {
      var pivDrawerButton = find.byKey(pivAppDrawer).hitTestable();
      await tester.tap(pivDrawerButton);
      await tester.longWait();
      // 2. click meatball menu for 9e
      await tester.tap(find.byKey(appListItem9e).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteAction).hitTestable());
      await tester.longWait();
      await tester.tap(find.byKey(deleteButton).hitTestable());
      await tester.longWait();
    });
  });
}
