import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

import 'oath_test_util.dart';
import 'test_util.dart';

Future<void> addDelay(int ms) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}

String generateIssuer(int index) {
  return 'issuer_${index.toString().padLeft(4, '0')}';
}

String generateName(int index) {
  return 'name_${index.toString().padLeft(4, '0')}';
}

String base32(int i) {
  var m = (i % 32);
  return m < 26 ? String.fromCharCode(65 + m) : '${2 + m - 26}';
}

/// generates 16 chars Base32 string
String generateSecret(int index) {
  return List.generate(16, (_) => base32(index)).toString();
}

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  var startupParams = {};

  if (isAndroid) {
    // default android parameters
    startupParams = {'dlg.beta.enabled': false, 'delay.startup': 5};
    testWidgets('Android app boot', (WidgetTester tester) async {
      // delay first start
      await tester.startUp(startupParams);
      // remove delay.startup
      startupParams = {'dlg.beta.enabled': false};
    });
  }

  group('OATH UI tests', () {
    // Validates that expected UI is present
    testWidgets('Menu items exist', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.tapDeviceButton();
      expect(find.byKey(OathDeviceMenu.addAccountKey), findsOneWidget);
      expect(find.byKey(OathDeviceMenu.setManagePasswordKey), findsOneWidget);
      expect(find.byKey(OathDeviceMenu.resetKey), findsOneWidget);
    });
  });

  group('OATH Account tests', () {
    testWidgets('Create account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

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

    // deletes accounts created in previous test
    testWidgets('Delete account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      var testAccount =
          const Account(issuer: 'IssuerForTests', name: 'NameForTests');

      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);

      testAccount = const Account(issuer: null, name: 'NoIssuerName');
      await tester.deleteAccount(testAccount, quiet: false);
      expect(await tester.findAccount(testAccount), isNull);
    });

    // adds an account, renames, verifies
    testWidgets('Rename account', (WidgetTester tester) async {
      await tester.startUp(startupParams);

      var testAccount =
          const Account(issuer: 'IssuerToRename', name: 'NameToRename');

      // delete account if it exists
      await tester.deleteAccount(testAccount);
      await tester.deleteAccount(
          const Account(issuer: 'RenamedIssuer', name: 'RenamedName'));

      await tester.addAccount(testAccount);
      await tester.renameAccount(testAccount, 'RenamedIssuer', 'RenamedName');
    });
  });

  group('OATH Password Quick tests', () {
    // note that the password groups should be run as whole
    // this is quick test as we cannot restart android app during 1 testrun
    testWidgets('OATH: set oath password', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.setOathPassword('aaa111');
    });

    /// note - we cannot 'restart' the app to [unlockOathApp]

    testWidgets('OATH: remove oath password', (WidgetTester tester) async {
      await tester.startUp(startupParams);
      await tester.removeOathPassword('aaa111');
    });
  });

  group('OATH Password tests', skip: true, () {
    /*
  These tests verify that all oath options are verified to function correctly by:
    1. setting firsPassword and verifying it
    2. logging in and changing to secondPassword and verifying it
    3. changing to thirdPassword
    4. removing thirdPassword
   */
    testWidgets('OATH: set firstPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('new oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), firstPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: verify firstPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';

      await tester.enterText(
          find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set secondPassword', (WidgetTester tester) async {
      await tester.startUp();

      var firstPassword = 'aaa111';
      var secondPassword = 'bbb222';

      await tester.enterText(
          find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('new oath password')), secondPassword);

      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), secondPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set thirdPassword', (WidgetTester tester) async {
      await tester.startUp();

      var secondPassword = 'bbb222';
      var thirdPassword = 'ccc333';

      await tester.enterText(
          find.byKey(const Key('oath password')), secondPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), secondPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('new oath password')), thirdPassword);
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('confirm oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));

      /// TODO: verification of state here: see that list of accounts is shown
    });

    testWidgets('OATH: remove thirdPassword', (WidgetTester tester) async {
      await tester.startUp();

      var thirdPassword = 'ccc333';

      await tester.enterText(
          find.byKey(const Key('oath password')), thirdPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(
          find.byKey(const Key('current oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Remove password'));

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
  group('TOTP tests', skip: true, () {
    /*
  Tests will verify all TOTP functionality, not yet though:
    1. Add 32 TOTP accounts
     */
    testWidgets('TOTP: Add 32 accounts', skip: true,
        (WidgetTester tester) async {
      await tester.startUp();

      for (var i = 0; i < 32; i++) {
        await tester.tapAddAccount();

        var issuer = generateIssuer(i);
        var name = generateName(i);
        var secret = generateSecret(i);

        await tester.enterText(find.byKey(const Key('issuer')), issuer);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.enterText(find.byKey(const Key('name')), name);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.enterText(find.byKey(const Key('secret')), secret);

        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byKey(const Key('save_btn')));

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(OathScreen), findsOneWidget);

        await tester.enterText(
            find.byKey(const Key('search_accounts')), issuer);

        await tester.pump(const Duration(milliseconds: 100));

        expect(
            find.descendant(
                of: find.byType(AccountList),
                matching: find.textContaining(issuer)),
            findsOneWidget);

        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 3000));
      /*
      TODO:
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset OATH'));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 500));

      */
    });
  });
}
