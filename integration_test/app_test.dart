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

  group('end-to-end test', () {
    testWidgets('Add account', (WidgetTester tester) async {
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

      expect(find.byType(NoDeviceScreen), findsNothing,
          reason: 'No YubiKey connected');
      expect(find.byType(OathScreen), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Add account'));
      await tester.pump(const Duration(milliseconds: 300));

      var issuer = generateRandomIssuer();
      var name = generateRandomName();
      var secret = generateRandomSecret();

      await tester.enterText(find.byKey(const Key('issuer')), issuer);
      await tester.enterText(find.byKey(const Key('name')), name);
      await tester.enterText(find.byKey(const Key('secret')), secret);

      await tester.pump();

      await tester.tap(find.byKey(const Key('save_btn')));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OathScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search_accounts')), issuer);

      await tester.pump(const Duration(milliseconds: 500));

      expect(
          find.descendant(
              of: find.byType(AccountList),
              matching: find.textContaining(issuer)),
          findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
