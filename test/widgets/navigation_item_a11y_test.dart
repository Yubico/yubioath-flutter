import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yubico_authenticator/app/views/navigation.dart';

void main() {
  testWidgets('NavigationItem only marks the active item as selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final selectedCollapsedKey = UniqueKey();
      final unselectedCollapsedKey = UniqueKey();
      final selectedExpandedKey = UniqueKey();
      final unselectedExpandedKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NavigationItem(
                  key: selectedCollapsedKey,
                  leading: const Icon(Icons.home),
                  title: 'Home',
                  collapsed: true,
                  selected: true,
                  onTap: () {},
                ),
                NavigationItem(
                  key: unselectedCollapsedKey,
                  leading: const Icon(Icons.supervisor_account),
                  title: 'Accounts',
                  collapsed: true,
                  selected: false,
                  onTap: () {},
                ),
                NavigationItem(
                  key: selectedExpandedKey,
                  leading: const Icon(Icons.home),
                  title: 'Home',
                  collapsed: false,
                  selected: true,
                  onTap: () {},
                ),
                NavigationItem(
                  key: unselectedExpandedKey,
                  leading: const Icon(Icons.supervisor_account),
                  title: 'Accounts',
                  collapsed: false,
                  selected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final selectedCollapsedMerged = find.descendant(
        of: find.byKey(selectedCollapsedKey),
        matching: find.byType(MergeSemantics),
      );
      final unselectedCollapsedMerged = find.descendant(
        of: find.byKey(unselectedCollapsedKey),
        matching: find.byType(MergeSemantics),
      );
      final selectedExpandedInkWell = find.descendant(
        of: find.byKey(selectedExpandedKey),
        matching: find.byType(InkWell),
      );
      final unselectedExpandedInkWell = find.descendant(
        of: find.byKey(unselectedExpandedKey),
        matching: find.byType(InkWell),
      );

      expect(selectedCollapsedMerged, findsOneWidget);
      expect(unselectedCollapsedMerged, findsOneWidget);
      expect(selectedExpandedInkWell, findsOneWidget);
      expect(unselectedExpandedInkWell, findsOneWidget);

      expect(
        tester.getSemantics(selectedCollapsedMerged).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(selectedCollapsedMerged).getSemanticsData().label,
        'Home',
      );
      expect(
        tester.getSemantics(unselectedCollapsedMerged).flagsCollection.isSelected,
        Tristate.none,
      );
      expect(
        tester.getSemantics(unselectedCollapsedMerged).getSemanticsData().label,
        'Accounts',
      );

      expect(
        tester.getSemantics(selectedExpandedInkWell).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(selectedExpandedInkWell).getSemanticsData().label,
        'Home',
      );
      expect(
        tester.getSemantics(unselectedExpandedInkWell).flagsCollection.isSelected,
        Tristate.none,
      );
      expect(
        tester.getSemantics(unselectedExpandedInkWell).getSemanticsData().label,
        'Accounts',
      );
    } finally {
      semantics.dispose();
    }
  });
}
