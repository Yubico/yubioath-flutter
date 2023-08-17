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
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/keys.dart' as keys;

import 'utils/oath_test_util.dart';
import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH UI tests', () {
    appTest('Menu items exist', (WidgetTester tester) async {
      await tester.tapActionIconButton();
      expect(find.byKey(keys.addAccountAction), findsOneWidget);
      expect(find.byKey(keys.setOrManagePasswordAction), findsOneWidget);
      expect(find.byKey(keys.resetAction), findsOneWidget);

      // close dialog
      await tester.tapTopLeftCorner();
    });
  });

  group('Account creation', () {
    appTest('Create 32+1 Accounts', (WidgetTester tester) async {  });
    appTest('Create weird character-accounts and check byte count', (WidgetTester tester) async {  });
    group('TOTP account tests', () {
      appTest('Create regular TOTP account', (WidgetTester tester) async {
      // account with issuer field
      var testAccount = const Account(
        issuer: 'IssuerForTests',
        name: 'NameForTests',
        secret: 'aaaaaaaaaaaaaaaa',
      );
      await tester.addAccount(testAccount);
      /// TODO: Change testAccount
      ///   Rename:       await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
      ///   Custom Icon:  await duddu
      ///   
      await tester.deleteAccount(testAccount);
      });

      appTest('Create issuer-less TOTP account', (WidgetTester tester) async {
        // account without issuer field
        testAccount = const Account(
          name: 'NoIssuerName',
          secret: 'bbbbbbbbbbbbbbbb',
        );
        await tester.deleteAccount(testAccount);
        /// TODO: change testAccount (rename, add icons)
        await tester.addAccount(testAccount);
      });
      appTest('Create TOTP account, 6-digits, SHA-1', (WidgetTester tester) async {  });
      appTest('Create TOTP account, 6-digits, SHA-256', (WidgetTester tester) async {  });
      appTest('Create TOTP account, 6-digits, SHA-512', (WidgetTester tester) async {  });
      appTest('Create TOTP account, 8-digits, SHA-1', (WidgetTester tester) async {  });
      appTest('Create TOTP account, 8-digits, SHA-256', (WidgetTester tester) async {  });
      appTest('Create TOTP account, 8-digits, SHA-512', (WidgetTester tester) async {  });
    });
    group('HOTP account tests', () {
      appTest('Create regular HOTP account', (WidgetTester tester) async {
        // account with issuer field
        var testAccount = const Account(
          issuer: 'IssuerForTests',
          name: 'NameForTests',
          secret: 'aaaaaaaaaaaaaaaa',
        );
        await tester.addAccount(testAccount);

        /// TODO: Change testAccount
        await tester.deleteAccount(testAccount);
      });
      appTest('Create issuer-less HOTP account', (WidgetTester tester) async {
        // account without issuer field
        testAccount = const Account(
          name: 'NoIssuerName',
          secret: 'bbbbbbbbbbbbbbbb',
        );
        await tester.deleteAccount(testAccount);

        /// TODO: change testAccount (rename, add icons)
        await tester.addAccount(testAccount);
      });
      appTest('Create HOTP account, 6-digits, SHA-1', (WidgetTester tester) async {});
      appTest('Create HOTP account, 6-digits, SHA-256', (WidgetTester tester) async {});
      appTest('Create HOTP account, 6-digits, SHA-512', (WidgetTester tester) async {});
      appTest('Create HOTP account, 8-digits, SHA-1', (WidgetTester tester) async {});
      appTest('Create HOTP account, 8-digits, SHA-256', (WidgetTester tester) async {});
      appTest('Create HOTP account, 8-digits, SHA-512', (WidgetTester tester) async {});
    });
    group('QR Code scanning', () {
    });


    appTest('Delete OATH account', (WidgetTester tester) async {
      var testAccount =
          const Account(issuer: 'IssuerForTests', name: 'NameForTests');

      await tester.deleteAccount(testAccount);
      expect(await tester.findAccount(testAccount), isNull);

      testAccount = const Account(issuer: null, name: 'NoIssuerName');
      await tester.deleteAccount(testAccount);
      expect(await tester.findAccount(testAccount), isNull);
    });
  });

  group('Password tests', () {
    /// note that the password groups should be run as whole

    /// TODO implement test for password replacement
    /// appTest('OATH: replace oath password', (WidgetTester tester) async {
    ///    await tester.replaceOathPassword('aaa111', 'bbb222');
    /// });

    // cannot restart the app on Android to be able to unlock
    group('Desktop password tests', skip: isAndroid, () {
      var testPassword = 'testPassword';

      appTest('Set first OATH password', (WidgetTester tester) async {
        await tester.setOathPassword(testPassword);
      });

      appTest('Set second OATH password', (WidgetTester tester) async {
        /// TODO: Without removing the first, set a second password
      };

      appTest('Set third OATH password', (WidgetTester tester) async {
        /// TODO: Without removing the second, set a third password
      };

      appTest('Remove OATH password', (WidgetTester tester) async {
        await tester.unlockOathSession(testPassword);
        await tester.removeOathPassword(testPassword);
      });
    });

    group('All password tests', () {
      var testPassword = 'testPasswordX';

      appTest('Set OATH password', (WidgetTester tester) async {
        await tester.setOathPassword(testPassword);
      });

      appTest('Remove OATH password', (WidgetTester tester) async {
        await tester.removeOathPassword(testPassword);
      });
    });
  });
}
