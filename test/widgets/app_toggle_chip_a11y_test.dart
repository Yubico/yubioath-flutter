import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yubico_authenticator/widgets/app_toggle_chip.dart';

void main() {
  testWidgets('AppToggleChip exposes checked semantics and toggles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: AppToggleChip(
                    key: const Key('pin-protect'),
                    label: const Text('Protect with PIN'),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        selected = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      final chipFinder = find.byKey(const Key('pin-protect'));
      expect(chipFinder, findsOneWidget);

      final checkboxFinder = find.descendant(
        of: chipFinder,
        matching: find.byType(Checkbox),
      );
      expect(checkboxFinder, findsOneWidget);

      final toggleSemantics = find.semantics.byLabel('Protect with PIN');
      expect(toggleSemantics, findsOneWidget);
      final toggleFinder = find.bySemanticsLabel('Protect with PIN');
      expect(toggleFinder, findsOneWidget);

      expect(
        tester.getSemantics(toggleFinder),
        matchesSemantics(
          label: 'Protect with PIN',
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
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      await tester.tap(chipFinder);
      await tester.pump();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
    } finally {
      semantics.dispose();
    }
  });
}
