import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

import 'test_util.dart';

Future<void> addDelay(int ms) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
}

int randomNum(int max) {
  var r = Random.secure();
  return r.nextInt(max);
}

String randomPadded() {
  return randomNum(999).toString().padLeft(3, '0');
}

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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH Options', () {
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

      /// expect(find.byType(OathScreen), findsOneWidget);  <<< I am not certain if this is needed.

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Set password'));
      await tester.pump(const Duration(milliseconds: 100));

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

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Manage password'));
      await tester.pump(const Duration(milliseconds: 100));

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

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Manage password'));
      await tester.pump(const Duration(milliseconds: 100));

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

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Manage password'));
      await tester.pump(const Duration(milliseconds: 100));

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

      for (var i = 0; i < 32; i += 1) {
        await tester.tap(find.byKey(const Key('add oath account')));
        await tester.pump(const Duration(milliseconds: 100));

        var issuer = generateRandomIssuer();
        var name = generateRandomName();
        var secret = 'abba';

        /// this random fails: generateRandomSecret();

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
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset OATH'));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 500));

      */
    });
  });
  /*
  group('HOTP tests', () {
    testWidgets('first HOTP test', (WidgetTester tester) async {
      await tester.pumpWidget(await getAuthenticatorApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OathScreen), findsOneWidget);
    });
  });

   */
}
