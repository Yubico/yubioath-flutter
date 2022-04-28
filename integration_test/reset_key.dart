import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/android/init.dart' as android;
import 'package:yubico_authenticator/app/logging.dart';
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

    group('Reset Key', () {

    testWidgets('Reset OATH', (WidgetTester tester) async {

      /// %%%%%%%%%%%%%%%%%%%%%%
      /// Cannot the following be lifted out to the group, instead of the testWidgets?

      final logBuffer = initLogBuffer(1000);

      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize();
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(LogBuffer(
        logBuffer,
        child: initializedApp,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      /// %%%%%%%%%%%%%%%%%%%%%%

      expect(find.byType(NoDeviceScreen), findsNothing,
          reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      /// QUESTION: I want to click the DrawerItem named 'WebAuthn' | 'Authenticator'
      ///       await tester.tap(find.byType(DrawerItem.titleText == 'WebAuthn'));
      /// which can be found in main_drawer.dart, how do I make sure I call the right
      /// thing here?
      await tester.tap(find.text('WebAuthn'));  /// get to correct widget
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(FloatingActionButton));  /// click the Setup Button
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset OATH'));  /// click reset oath
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset'));   /// confirm
      await tester.pump(const Duration(milliseconds: 300));

      /// The following should report 'No accounts' in Authenticator widget.
      /// Maybe through find.bySemanticsLabel or byTooltip?
      expect(find.byType(OathScreen), findsNothing,
          reason: 'OATH successfully reset.');

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Reset FIDO', (WidgetTester tester) async {
      final logBuffer = initLogBuffer(1000);

      final Widget initializedApp;
      if (isDesktop) {
        initializedApp = await desktop.initialize();
      } else if (isAndroid) {
        initializedApp = await android.initialize();
      } else {
        throw UnimplementedError('Platform not supported');
      }

      await tester.pumpWidget(LogBuffer(
        logBuffer,
        child: initializedApp,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NoDeviceScreen), findsNothing,
          reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      /// QUESTION: I want to click the DrawerItem named 'WebAuthn' | 'Authenticator'
      ///       await tester.tap(find.byType(DrawerItem.titleText == 'WebAuthn'));
      /// which can be found in main_drawer.dart, how do I make sure I call the right
      /// thing here?
      await tester.tap(find.text('WebAuthn'));  /// get to correct widget
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(FloatingActionButton));  /// click the Setup Button
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset OATH'));
      await tester.pump(const Duration(milliseconds: 300));

      /// For this reset you require the yubikey-dance, giving user 30s for this
      await tester.tap(find.text('Reset'));
      await tester.pump(const Duration(milliseconds: 30000));

      /// The following should report the success, if there are no accounts.
      expect(find.byType(OathScreen), findsNothing,
          reason: 'FIDO successfully reset.');

      await tester.pump(const Duration(seconds: 3));
    });

  };
};
