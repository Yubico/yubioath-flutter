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

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/keys.dart' as keys;

import 'utils/oath_test_util.dart';
import 'utils/test_util.dart';

String randomPadded() {
  return randomNum(999).toString().padLeft(3, '0');
}

randomNum(int i) {}

String generateRandomIssuer() {
  return 'i${randomPadded()}';
}

String generateRandomName() {
  return 'n${randomPadded()}';
}

String generateRandomSecret() {
  final random = Random.secure();
  return base64Encode(List.generate(10, (_) => random.nextInt(256)));
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH UI tests', () {
    appTest('Menu items exist', (WidgetTester tester) async {
      await tester.tapActionIconButton();
      await tester.shortWait();
      expect(find.byKey(keys.addAccountAction), findsOneWidget);
      expect(find.byKey(keys.setOrManagePasswordAction), findsOneWidget);
      expect(find.byKey(keys.resetAction), findsOneWidget);
      // close dialog
      await tester.tapTopLeftCorner();
      await tester.longWait();
    });
  });

  group('Account creation', () {
    appTest('Initial reset OATH', (WidgetTester tester) async {
      /// reset OATH application
      var oathDrawerButton = find.byKey(oathAppDrawer).hitTestable();
      await tester.tap(oathDrawerButton);
      await tester.longWait();
      await tester.resetOATH();
      await tester.longWait();
    });
    appTest('Create 32 Accounts', (WidgetTester tester) async {
      // just now merely 32 accounts
      var testAccount = const Account(
        issuer: 'IssuerForTests',
        name: 'NameForTests',
        secret: 'abcdabcd',
      );
      var oathDrawerButton = find.byKey(oathAppDrawer).hitTestable();
      await tester.tap(oathDrawerButton);
      await tester.longWait();

      /// TODO change back to 32 after flakiness eval
      for (var i = 0; i < 10; i += 1) {
        await tester.addAccount(testAccount);
        await tester.longWait();

        // expect(
        //     find.descendant(
        //         of: find.byType(AccountList),
        //         matching: find.textContaining(issuer)),
        //     findsOneWidget);
        //
        // await tester.pump(const Duration(milliseconds: 50));
      }
      // TODO: verify one more addAccount() is not possible
      await tester.resetOATH();
      await tester.shortWait();
    });
    // appTest('Create weird character-accounts and check byte count',
    //     (WidgetTester tester) async {});
    group('TOTP account tests', () {
      appTest('Create regular TOTP account', (WidgetTester tester) async {
        // account with issuer field
        // var issuer = generateRandomIssuer();
        // var name = generateRandomName();
        // var secret = 'abcdabcd';
        var testAccount = const Account(
          issuer: 'IssuerForTests',
          name: 'NameForTests',
          secret: 'abcdabcd',
        );
        var oathDrawerButton = find.byKey(oathAppDrawer).hitTestable();
        await tester.tap(oathDrawerButton);
        await tester.longWait();

        await tester.addAccount(testAccount);
        await tester.longWait();

        // TODO: Verify account exists
        // TODO: Change testAccount
        await tester.deleteAccount(testAccount);
      });

      appTest('Create issuer-less TOTP account', (WidgetTester tester) async {
        // account without issuer field
        var testAccount = const Account(
          name: 'NoIssuerName',
          secret: 'bbbbbbbbbbbbbbbb',
        );
        await tester.deleteAccount(testAccount);

        /// TODO: change issuer functionality in oath_test_util
        await tester.addAccount(testAccount);
      });
      // appTest('Create TOTP account, 6-digits, SHA-1',
      //     (WidgetTester tester) async {});
      // appTest('Create TOTP account, 6-digits, SHA-256',
      //     (WidgetTester tester) async {});
      // appTest('Create TOTP account, 6-digits, SHA-512',
      //     (WidgetTester tester) async {});
      // appTest('Create TOTP account, 8-digits, SHA-1',
      //     (WidgetTester tester) async {});
      // appTest('Create TOTP account, 8-digits, SHA-256',
      //     (WidgetTester tester) async {});
      // appTest('Create TOTP account, 8-digits, SHA-512',
      //     (WidgetTester tester) async {});
    });
    // group('HOTP account tests', () {
    //   appTest('Create regular HOTP account', (WidgetTester tester) async {});
    //   appTest(
    //       'Create issuer-less HOTP account', (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 6-digits, SHA-1',
    //       (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 6-digits, SHA-256',
    //       (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 6-digits, SHA-512',
    //       (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 8-digits, SHA-1',
    //       (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 8-digits, SHA-256',
    //       (WidgetTester tester) async {});
    //   appTest('Create HOTP account, 8-digits, SHA-512',
    //       (WidgetTester tester) async {});
    // });
    // group('QR Code scanning', () {});
    //
    // appTest('Delete OATH account', (WidgetTester tester) async {
    //   /// TODO deleteAccount
    //   var testAccount =
    //       const Account(issuer: 'IssuerForTests', name: 'NameForTests');
    //
    //   await tester.addAccount(testAccount);
    //   expect(await tester.findAccount(testAccount), isNull);
    //
    //   testAccount = const Account(issuer: null, name: 'NoIssuerName');
    //   await tester.deleteAccount(testAccount);
    //   expect(await tester.findAccount(testAccount), isNull);
    // });
    appTest('Final reset OATH', (WidgetTester tester) async {
      /// reset OATH application
      var oathDrawerButton = find.byKey(oathAppDrawer).hitTestable();
      await tester.tap(oathDrawerButton);
      await tester.longWait();
      await tester.resetOATH();
      await tester.longWait();
    });
  });

  group('Password tests', () {
    // NOTE: that the password groups should be run as whole
    // NOTE: cannot restart the app on Android to be able to unlock: skip
    group('Desktop password tests', skip: isAndroid, () {
      var firstPassword = 'firstPassword';
      var secondPassword = 'secondPassword';
      var thirdPassword = 'thirdPassword';
      appTest('Set first OATH password', (WidgetTester tester) async {
        // await tester.resetOath();
      });
      appTest('Set first OATH password', (WidgetTester tester) async {
        // Sets a password for OATH
        await tester.setOathPassword(firstPassword);
      });

      appTest('Set second OATH password', (WidgetTester tester) async {
        // Without removing the first, change to a second password
        await tester.unlockOathSession(firstPassword);
        await tester.replaceOathPassword(firstPassword, secondPassword);
      });

      appTest('Set third OATH password', (WidgetTester tester) async {
        // Without removing the second, set a third password
        await tester.unlockOathSession(secondPassword);
        await tester.replaceOathPassword(secondPassword, thirdPassword);
      });

      appTest('Remove OATH password', (WidgetTester tester) async {
        // restarts the app, unlocks with password, removes password req.
        await tester.unlockOathSession(thirdPassword);
        await tester.removeOathPassword(thirdPassword);
      });
    });
  });
}
