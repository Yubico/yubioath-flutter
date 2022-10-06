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

import 'oath_test_util.dart';
import 'test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH UI tests', () {
    appTest('Menu items exist', (WidgetTester tester) async {
      await tester.tapDeviceButton();
      expect(find.byKey(keys.addAccountAction), findsOneWidget);
      expect(find.byKey(keys.setOrManagePasswordAction), findsOneWidget);
      expect(find.byKey(keys.resetAction), findsOneWidget);
    });
  });

  group('OATH Account tests', () {
    appTest('Create account', (WidgetTester tester) async {
      // account with issuer
      var testAccount = const Account(
        issuer: 'IssuerForTests',
        name: 'NameForTests',
        secret: 'aaaaaaaaaaaaaaaa',
      );

      await tester.deleteAccount(testAccount);
      await tester.addAccount(testAccount, quiet: false);

      // account without issuer
      testAccount = const Account(
        name: 'NoIssuerName',
        secret: 'bbbbbbbbbbbbbbbb',
      );

      await tester.deleteAccount(testAccount);
      await tester.addAccount(testAccount, quiet: false);
    });

    /// deletes accounts created in previous test
    appTest('Delete account', (WidgetTester tester) async {
      var testAccount =
          const Account(issuer: 'IssuerForTests', name: 'NameForTests');

      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);

      testAccount = const Account(issuer: null, name: 'NoIssuerName');
      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);
    });

    /// adds an account, renames, verifies
    appTest('Rename account', (WidgetTester tester) async {
      var testAccount =
          const Account(issuer: 'IssuerToRename', name: 'NameToRename');

      /// delete account if it exists
      await tester.deleteAccount(testAccount);
      await tester.deleteAccount(
          const Account(issuer: 'RenamedIssuer', name: 'RenamedName'));

      await tester.addAccount(testAccount);
      await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
    });
  });

  group('OATH Password tests', () {
    /// note that the password groups should be run as whole

    /// TODO implement test for password replacement
    /// appTest('OATH: replace oath password', (WidgetTester tester) async {
    ///    await tester.replaceOathPassword('aaa111', 'bbb222');
    /// });

    // cannot restart the app on Android to be able to unlock
    group('OATH: remove oath password when unlocked', skip: isAndroid, () {
      var testPassword = 'testPassword';

      appTest('OATH: set oath password', (WidgetTester tester) async {
        await tester.setOathPassword(testPassword);
      });

      appTest('OATH: remove oath password', (WidgetTester tester) async {
        await tester.unlockOathSession(testPassword);
        await tester.removeOathPassword(testPassword);
      });
    });

    group('OATH: remove oath password when locked', () {
      var testPassword = 'testPasswordX';

      appTest('OATH: set oath password', (WidgetTester tester) async {
        await tester.setOathPassword(testPassword);
      });

      appTest('OATH: remove oath password', (WidgetTester tester) async {
        await tester.removeOathPassword(testPassword);
      });
    });
  });
}
