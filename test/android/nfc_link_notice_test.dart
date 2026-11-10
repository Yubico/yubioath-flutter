/*
 * Copyright (C) 2026 Yubico.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/android/app_methods.dart';
import 'package:yubico_authenticator/android/models.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/android/views/nfc_link_notice.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as keys;
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';

/// Answers `app.methods` calls the way `MainActivity` does, with
/// [status] as the wire value of `getDomainVerificationStatus`.
class _FakeAppMethods {
  String? status;
  final calls = <String>[];

  _FakeAppMethods(this.status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appMethodsChannel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'getDomainVerificationStatus' => status,
            'openDomainVerificationSettings' => true,
            _ => null,
          };
        });
  }

  int count(String method) => calls.where((m) => m == method).length;
}

/// Shared preferences holding [action], as `NfcTapActionNotifier` stores it.
Future<SharedPreferences> _prefsFor(NfcTapAction action) async {
  SharedPreferences.setMockInitialValues({
    'prefNfcOpenApp':
        action == NfcTapAction.launch || action == NfcTapAction.launchAndCopy,
    'prefNfcCopyOtp':
        action == NfcTapAction.copy || action == NfcTapAction.launchAndCopy,
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpNotice(WidgetTester tester, NfcTapAction action) async {
  final prefs = await _prefsFor(action);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NfcLinkNotice(isDialog: false)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appMethodsChannel, null);
  });

  group('getDomainVerificationStatus', () {
    // The wire values of `DomainVerificationHelper.Status` in Kotlin, which
    // `DomainVerificationHelperTest.kt` pins to the same strings.
    const wireValues = {
      'unsupported': DomainVerificationStatus.unsupported,
      'verified': DomainVerificationStatus.verified,
      'selected': DomainVerificationStatus.selected,
      'none': DomainVerificationStatus.none,
    };

    test('decodes every Kotlin wire value', () async {
      final fake = _FakeAppMethods(null);
      for (final entry in wireValues.entries) {
        fake.status = entry.key;
        expect(await getDomainVerificationStatus(), entry.value);
      }
      expect(
        wireValues.values.toSet(),
        DomainVerificationStatus.values.toSet(),
      );
    });

    test('unknown or missing values are not applicable', () async {
      // Never `none`: an unreadable state must not tell the user to change
      // a setting that may already be correct.
      final fake = _FakeAppMethods(null);
      expect(
        await getDomainVerificationStatus(),
        DomainVerificationStatus.unsupported,
      );
      fake.status = 'something_new';
      expect(
        await getDomainVerificationStatus(),
        DomainVerificationStatus.unsupported,
      );
    });
  });

  group('NfcLinkNotice', () {
    for (final action in [
      NfcTapAction.launch,
      NfcTapAction.copy,
      NfcTapAction.launchAndCopy,
    ]) {
      testWidgets('shown for ${action.name} when links are not handled', (
        tester,
      ) async {
        // Copy-only depends on the link too: MainActivity enables the NDEF
        // alias for copy as well as launch.
        _FakeAppMethods('none');
        await _pumpNotice(tester, action);
        expect(find.byKey(keys.nfcLinkNotice), findsOneWidget);
      });
    }

    testWidgets('hidden when the tap action is do nothing', (tester) async {
      _FakeAppMethods('none');
      await _pumpNotice(tester, NfcTapAction.noAction);
      expect(find.byKey(keys.nfcLinkNotice), findsNothing);
    });

    for (final status in ['verified', 'selected', 'unsupported']) {
      testWidgets('hidden when the status is $status', (tester) async {
        _FakeAppMethods(status);
        await _pumpNotice(tester, NfcTapAction.launch);
        expect(find.byKey(keys.nfcLinkNotice), findsNothing);
      });
    }

    testWidgets('opens Open by default settings when tapped', (tester) async {
      final fake = _FakeAppMethods('none');
      await _pumpNotice(tester, NfcTapAction.launch);
      await tester.tap(find.byKey(keys.nfcLinkNotice));
      await tester.pumpAndSettle();
      expect(fake.count('openDomainVerificationSettings'), 1);
    });
  });

  group('androidDomainVerificationStatusProvider', () {
    test(
      'reads the status again when the app returns to the foreground',
      () async {
        // Covers the user coming back from system settings after adding the
        // link: the notice must disappear without restarting the app.
        final fake = _FakeAppMethods('none');
        final window = StateProvider<WindowState>(
          (ref) => WindowState(focused: true, visible: true, active: true),
        );
        final container = ProviderContainer(
          overrides: [
            windowStateProvider.overrideWith((ref) => ref.watch(window)),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(
          androidDomainVerificationStatusProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        expect(
          await container.read(androidDomainVerificationStatusProvider.future),
          DomainVerificationStatus.none,
        );

        container.read(window.notifier).state = WindowState(
          focused: false,
          visible: false,
          active: false,
        );
        await container.read(androidDomainVerificationStatusProvider.future);
        fake.status = 'selected';
        container.read(window.notifier).state = WindowState(
          focused: true,
          visible: true,
          active: true,
        );

        expect(
          await container.read(androidDomainVerificationStatusProvider.future),
          DomainVerificationStatus.selected,
        );
        expect(fake.count('getDomainVerificationStatus'), 3);
      },
    );
  });
}
