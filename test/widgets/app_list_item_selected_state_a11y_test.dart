import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/views/app_list_item.dart';

void main() {
  testWidgets('AppListItem only exposes selected state when selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  AppListItem(
                    key: Key('unselected'),
                    1,
                    title: 'Unselected item',
                    subtitle: 'Subtitle',
                    selected: false,
                  ),
                  AppListItem(
                    key: Key('selected'),
                    2,
                    title: 'Selected item',
                    subtitle: 'Subtitle',
                    selected: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final unselected = tester.getSemantics(find.byKey(const Key('unselected')));
      expect(unselected.flagsCollection.isSelected, Tristate.none);

      final selected = tester.getSemantics(find.byKey(const Key('selected')));
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    } finally {
      semantics.dispose();
    }
  });
}
