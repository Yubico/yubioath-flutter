import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

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

extension OathHelper on WidgetTester {

  /// Opens the device menu and taps the "Add account" menu item
  Future<void> tapAddAccount() async {
    await tapDeviceButton();
    await tap(find.byKey(const Key('add oath account')));
    await pump(const Duration(milliseconds: 500));
  }

  /// Opens the device menu and taps the "Set/Manage password" menu item
  Future<void> tapSetOrManagePassword() async {
    await pump(const Duration(milliseconds: 300));
    await tapDeviceButton();
    await tap(find.byKey(const Key('set or manage oath password')));
    await pump(const Duration(milliseconds: 500));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH UI tests', () {
    // Validates that expected UI is present
    testWidgets(
        'OATH UI: "Add account" menu item exists', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapDeviceButton();
      expect(find.byKey(const Key('add oath account')), findsOneWidget);
    });

    testWidgets('OATH-UI: "Set or manage oath password" menu item exists', (
        WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapDeviceButton();
      expect(
          find.byKey(const Key('set or manage oath password')), findsOneWidget);
    });

    testWidgets(
        'OATH-UI: "Reset OATH" menu item exists', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapDeviceButton();
      expect(find.byKey(const Key('reset oath app')), findsOneWidget);
    });
  });

  group('OATH Password tests', () {
    /*
  These tests verify that all oath options are verified to function correctly by:
    1. setting firsPassword and verifying it
    2. logging in and changing to secondPassword and verifying it
    3. changing to thirdPassword
    4. removing thirdPassword
   */
    testWidgets('OATH: set firstPassword', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      var firstPassword = 'aaa111';

      await tester.tapSetOrManagePassword();

      await tester.enterText(find.byKey(const Key('new oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('confirm oath password')), firstPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: verify firstPassword', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      var firstPassword = 'aaa111';

      await tester.enterText(find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set secondPassword', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      var firstPassword = 'aaa111';
      var secondPassword = 'bbb222';

      await tester.enterText(find.byKey(const Key('oath password')), firstPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));


      await tester.tapSetOrManagePassword();

      await tester.enterText(find.byKey(const Key('current oath password')), firstPassword);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('new oath password')), secondPassword);

      await tester.pump();
      await tester.enterText(find.byKey(const Key('confirm oath password')), secondPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));
    });
    testWidgets('OATH: set thirdPassword', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      var secondPassword = 'bbb222';
      var thirdPassword = 'ccc333';

      await tester.enterText(find.byKey(const Key('oath password')), secondPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(find.byKey(const Key('current oath password')), secondPassword);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('new oath password')), thirdPassword);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('confirm oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 1000));

      /// TODO: verification of state here: see that list of accounts is shown
    });

    testWidgets('OATH: remove thirdPassword', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      var thirdPassword = 'ccc333';

      await tester.enterText(find.byKey(const Key('oath password')), thirdPassword);
      await tester.pump();
      await tester.tap(find.byKey(const Key('oath unlock')));

      await tester.tapSetOrManagePassword();

      await tester.enterText(find.byKey(const Key('current oath password')), thirdPassword);
      await tester.pump();

      await tester.tap(find.text('Remove password'));

      /// TODO: verification of state here: see that list of accounts is shown
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
  group('TOTP tests', () {
    /*
  Tests will verify all TOTP functionality, not yet though:
    1. Add 32 TOTP accounts
     */
    testWidgets('TOTP: Add 32 accounts', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

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

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(OathScreen), findsOneWidget);

        await tester.enterText(find.byKey(const Key('search_accounts')), issuer);

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.descendant(of: find.byType(AccountList), matching: find.textContaining(issuer)), findsOneWidget);

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
