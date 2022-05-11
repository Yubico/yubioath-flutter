import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/android/init.dart' as android;
import 'package:yubico_authenticator/app/views/no_device_screen.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/init.dart' as desktop;
import 'package:yubico_authenticator/oath/views/account_list.dart';
import 'package:yubico_authenticator/oath/views/oath_screen.dart';

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
  return 'i' + randomPadded();
}

String generateRandomName() {
  return 'n' + randomPadded();
}

String generateRandomSecret() {
  final random = Random.secure();
  return base64Encode(List.generate(10, (_) => random.nextInt(256)));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('OATH tests', () {
    /// For these tests there are defined Keys in manage_password_dialog.dart
    testWidgets('set password', (WidgetTester tester) async {
      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize([]);
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(initializedApp);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing, reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Set password'));
      await tester.pump(const Duration(milliseconds: 300));

      var first_password = 'aaa111';

      /// TODO: I don't understand why these Keys don't work as intended
      await tester.enterText(find.byKey(const Key('new oath password')), first_password);
      await tester.enterText(find.byKey(const Key('confirm oath password')), first_password);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 300));

      /// TODO: verification of state here: restarting app and entering password
      await tester.pump(const Duration(seconds: 3));
    });
    testWidgets('change password', (WidgetTester tester) async {
      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize([]);
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(initializedApp);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing, reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Manage password'));
      await tester.pump(const Duration(milliseconds: 300));

      var current_password = 'aaa111';
      var second_password = 'bbb222';

      /// TODO: I don't understand why these Keys don't work as intended
      await tester.enterText(find.byKey(const Key('current oath password')), current_password);
      await tester.enterText(find.byKey(const Key('new oath password')), second_password);
      await tester.enterText(find.byKey(const Key('confirm oath password')), second_password);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 300));

      /// TODO: verification of state here: restarting app and entering password
      await tester.pump(const Duration(seconds: 3));
    });
    testWidgets('remove password', (WidgetTester tester) async {
      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize([]);
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(initializedApp);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing, reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Manage password'));
      await tester.pump(const Duration(milliseconds: 300));

      var second_password = 'bbb222';
      await tester.enterText(find.byKey(const Key('current oath password')), second_password);
      await tester.pump();

      await tester.tap(find.text('Remove password'));
      await tester.pump(const Duration(milliseconds: 300));

      /// TODO: verification of state here: restarting app and entering password
      await tester.pump(const Duration(seconds: 3));
    });
  });
  group('TOTP tests', () {
    testWidgets('Add 32 TOTP accounts and reset oath', (WidgetTester tester) async {
      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize([]);
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(initializedApp);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing, reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      for (var i = 0; i < 32; i += 1) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Add account'));
        await tester.pump(const Duration(milliseconds: 300));

        var issuer = generateRandomIssuer();
        var name = generateRandomName();
        var secret = 'abba';

        /// this random fails: generateRandomSecret();

        await tester.enterText(find.byKey(const Key('issuer')), issuer);
        await tester.pump(const Duration(milliseconds: 5));
        await tester.enterText(find.byKey(const Key('name')), name);
        await tester.pump(const Duration(milliseconds: 5));
        await tester.enterText(find.byKey(const Key('secret')), secret);

        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const Key('save_btn')));

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(OathScreen), findsOneWidget);

        await tester.enterText(find.byKey(const Key('search_accounts')), issuer);

        await tester.pump(const Duration(milliseconds: 500));

        expect(find.descendant(of: find.byType(AccountList), matching: find.textContaining(issuer)), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset OATH'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pump(const Duration(seconds: 3));
    });
  });
  group('HOTP tests', () {
    testWidgets('first HOTP test', (WidgetTester tester) async {
      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize([]);
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(initializedApp);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing, reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);
    });
  });
}
