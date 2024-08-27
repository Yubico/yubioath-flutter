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
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/keys.dart' as keys;
import 'package:yubico_authenticator/oath/models.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';

import 'utils/oath_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH UI tests', () {
    appTest('Menu items exist', (WidgetTester tester) async {
      await tester.tapActionIconButton();
      await tester.shortWait();
      expect(find.byKey(keys.addAccountAction), findsOneWidget);
      expect(find.byKey(keys.setOrManagePasswordAction), findsOneWidget);
      // close dialog
      await tester.tapTopLeftCorner();
      await tester.longWait();
    });
  });

  group('Account creation', () {
    appTest('Initial reset OATH', (WidgetTester tester) async {
      /// reset OATH application
      //await tester.tapAppDrawerButton(oathAppDrawer);
      await tester.resetOATH();
      await tester.shortWait();
    });
    appTest('Create 32 Accounts', (WidgetTester tester) async {
      await tester.tapAppDrawerButton(oathAppDrawer);

      for (var i = 0; i < 32; i += 1) {
        // just now merely 32 accounts
        var testAccount = Account(
          issuer: 'MaxAccount_issuer_$i',
          name: 'MaxAccount_name_$i',
          secret: 'abbaabba',
        );
        await tester.addAccount(testAccount);
        await tester.shortWait();

        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(testAccount.name)),
            findsOneWidget);

        await tester.shortWait();
      }
      // TODO: verify one more addAccount() is not possible
      await tester.resetOATH();
      await tester.shortWait();
    }, tags: ['slow']);
    // appTest('Create weird character-accounts and check byte count',
    //     (WidgetTester tester) async {});
    group('TOTP account tests', () {
      appTest('TOTP: sha-1', (WidgetTester tester) async {
        await tester.tapAppDrawerButton(oathAppDrawer);
        const testAccount = Account(
            issuer: 'i_totp_sha1',
            name: 'n__totp_sha1',
            secret: 'abbaabba',
            touch: false,
            oathType: OathType.totp,
            hashAlgorithm: HashAlgorithm.sha1);
        await tester.addAccount(testAccount);
        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(testAccount.name)),
            findsOneWidget);

        await tester.shortWait();
      });
      appTest('TOTP: sha-256', (WidgetTester tester) async {
        await tester.tapAppDrawerButton(oathAppDrawer);
        const testAccount = Account(
            issuer: 'i_totp_sha256',
            name: 'n__totp_sha256',
            secret: 'abbaabba',
            touch: false,
            oathType: OathType.totp,
            hashAlgorithm: HashAlgorithm.sha256);
        await tester.addAccount(testAccount);
        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(testAccount.name)),
            findsOneWidget);

        await tester.shortWait();
      });
      appTest('TOTP: sha-512', (WidgetTester tester) async {
        await tester.tapAppDrawerButton(oathAppDrawer);
        const testAccount = Account(
            issuer: 'i_totp_sha512',
            name: 'n__totp_sha512',
            secret: 'abbaabba',
            touch: false,
            oathType: OathType.totp,
            hashAlgorithm: HashAlgorithm.sha512);
        await tester.addAccount(testAccount);
        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(testAccount.name)),
            findsOneWidget);

        await tester.shortWait();
      });
      // appTest('TOTP: period-20',
      //     (WidgetTester tester) async {});
      // appTest('TOTP: period-45',
      //     (WidgetTester tester) async {});
      // appTest('TOTP: period-60',
      //     (WidgetTester tester) async {});
      // appTest('TOTP: digits-8',
      //     (WidgetTester tester) async {});
      appTest('TOTP: touch', (WidgetTester tester) async {
        await tester.tapAppDrawerButton(oathAppDrawer);
        const testAccount = Account(
            issuer: 'i_totp_touch',
            name: 'n_totp_touch',
            secret: 'abbaabba',
            touch: true,
            oathType: OathType.totp,
            hashAlgorithm: HashAlgorithm.sha1);
        await tester.addAccount(testAccount);
        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(testAccount.name)),
            findsOneWidget);
        await tester.shortWait();
      });
    });
    // group('HOTP account tests', () {
    appTest('HOTP: sha-1', (WidgetTester tester) async {
      await tester.tapAppDrawerButton(oathAppDrawer);
      const testAccount = Account(
          issuer: 'i_hotp_sha1',
          name: 'n__hotp_sha1',
          secret: 'abbaabba',
          touch: false,
          oathType: OathType.hotp,
          hashAlgorithm: HashAlgorithm.sha1);
      await tester.addAccount(testAccount);
      expect(
          find.descendant(
              of: find.byType(AccountList),
              matching: find.textContaining(testAccount.name)),
          findsOneWidget);

      await tester.shortWait();
    });
    appTest('HOTP: sha-256', (WidgetTester tester) async {
      await tester.tapAppDrawerButton(oathAppDrawer);
      const testAccount = Account(
          issuer: 'i_hotp_sha256',
          name: 'n__hotp_sha256',
          secret: 'abbaabba',
          touch: false,
          oathType: OathType.hotp,
          hashAlgorithm: HashAlgorithm.sha256);
      await tester.addAccount(testAccount);
      expect(
          find.descendant(
              of: find.byType(AccountList),
              matching: find.textContaining(testAccount.name)),
          findsOneWidget);

      await tester.shortWait();
    });
    appTest('HOTP: sha-512', (WidgetTester tester) async {
      await tester.tapAppDrawerButton(oathAppDrawer);
      const testAccount = Account(
          issuer: 'i_hotp_sha512',
          name: 'n__hotp_sha512',
          secret: 'abbaabba',
          touch: false,
          oathType: OathType.hotp,
          hashAlgorithm: HashAlgorithm.sha512);
      await tester.addAccount(testAccount);
      expect(
          find.descendant(
              of: find.byType(AccountList),
              matching: find.textContaining(testAccount.name)),
          findsOneWidget);

      await tester.shortWait();
    });
    // appTest('TOTP: digits-8',
    //     (WidgetTester tester) async {});
    appTest('HOTP: touch', (WidgetTester tester) async {
      await tester.tapAppDrawerButton(oathAppDrawer);
      const testAccount = Account(
          issuer: 'i_hotp_touch',
          name: 'n_hotp_touch',
          secret: 'abbaabba',
          touch: true,
          oathType: OathType.hotp,
          hashAlgorithm: HashAlgorithm.sha1);
      await tester.addAccount(testAccount);
      expect(
          find.descendant(
              of: find.byType(AccountList),
              matching: find.textContaining(testAccount.name)),
          findsOneWidget);
      await tester.shortWait();
    });
    // group('QR Code scanning', () {});
    appTest('Final reset OATH', (WidgetTester tester) async {
      /// reset OATH application
      await tester.tapAppDrawerButton(oathAppDrawer);
      await tester.resetOATH();
      await tester.longWait();
    });

    /// adds an account, renames, verifies
    appTest('Rename OATH account', (WidgetTester tester) async {
      var testAccount =
          const Account(issuer: 'IssuerToRename', name: 'NameToRename');

      /// delete account if it exists
      await tester.deleteAccount(testAccount);
      await tester.deleteAccount(
          const Account(issuer: 'RenamedIssuer', name: 'RenamedName'));
      await tester.longWait();
      await tester.addAccount(testAccount);
      await tester.longWait();
      await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
    });
  });

  group('Password tests', () {
    // NOTE: that the password groups should be run as whole
    // NOTE: cannot restart the app on Android to be able to unlock: skip
    group('Desktop password tests', skip: isAndroid, () {
      var firstPassword = 'firstPassword';
      var secondPassword = 'secondPassword';
      var thirdPassword = 'thirdPassword';
      appTest('Reset OATH', (WidgetTester tester) async {
        await tester.resetOATH();
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
