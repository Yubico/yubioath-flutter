import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/oath/keys.dart' as oath_keys;
import 'package:yubico_authenticator/oath/models.dart';
import 'package:yubico_authenticator/oath/views/add_account_page.dart';

class _FakeCurrentDeviceNotifier extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() => null;

  @override
  void setCurrentDevice(DeviceNode? device) {
    state = device;
  }
}

void main() {
  testWidgets('Require touch exposes checked state and toggles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceProvider.overrideWith(
              () => _FakeCurrentDeviceNotifier(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: OathAddAccountPage(
                null,
                null,
                credentials: const <OathCredential>[],
              ),
            ),
          ),
        ),
      );

      final chipFinder = find.byKey(oath_keys.requireTouchFilterChip);
      await tester.ensureVisible(chipFinder);

      final checkboxFinder = find.descendant(
        of: chipFinder,
        matching: find.byType(Checkbox),
      );
      expect(checkboxFinder, findsOneWidget);

      final toggleSemantics = find.semantics.byLabel('Require touch');
      expect(toggleSemantics, findsOneWidget);
      final toggleFinder = find.bySemanticsLabel('Require touch');
      expect(toggleFinder, findsOneWidget);

      expect(
        tester.getSemantics(toggleFinder),
        matchesSemantics(
          label: 'Require touch',
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      tester.semantics.tap(toggleSemantics);
      await tester.pump();

      expect(
        tester.getSemantics(toggleFinder).flagsCollection.isChecked,
        CheckedState.isTrue,
      );

      tester.semantics.tap(toggleSemantics);
      await tester.pump();

      expect(
        tester.getSemantics(toggleFinder).flagsCollection.isChecked,
        CheckedState.isFalse,
      );

      await tester.tap(chipFinder);
      await tester.pump();

      expect(
        tester.getSemantics(toggleFinder).flagsCollection.isChecked,
        CheckedState.isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });
}
