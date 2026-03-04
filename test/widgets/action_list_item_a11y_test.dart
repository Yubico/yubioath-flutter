import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yubico_authenticator/app/views/action_list.dart';

void main() {
  testWidgets('ActionListItem does not expose selected semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionListItem(
              icon: const Icon(Icons.file_present),
              title: 'Export certificate',
              subtitle: 'Save certificate to file',
              onTap: (_) {},
            ),
          ),
        ),
      );

      final inkWellFinder = find.descendant(
        of: find.byType(ActionListItem),
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsOneWidget);

      final node = tester.getSemantics(inkWellFinder);
      expect(node.flagsCollection.isSelected, Tristate.none);
    } finally {
      semantics.dispose();
    }
  });
}
