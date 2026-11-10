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
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yubico_authenticator/widgets/warning_list_item.dart';

Future<ColorScheme> _pump(WidgetTester tester, Widget item) async {
  final theme = ThemeData(colorSchemeSeed: Colors.lightGreen);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: item),
    ),
  );
  return theme.colorScheme;
}

void main() {
  testWidgets('draws on the tertiary container with matching text', (
    tester,
  ) async {
    final colors = await _pump(
      tester,
      const WarningListItem(title: 'Title', subtitle: 'Subtitle'),
    );

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.byType(ListTile), matching: find.byType(Material))
          .first,
    );
    expect(material.color, colors.tertiaryContainer);

    final title = tester.widget<RichText>(
      find.descendant(of: find.text('Title'), matching: find.byType(RichText)),
    );
    expect(title.text.style?.color, colors.onTertiaryContainer);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byIcon(Symbols.warning_amber), findsOneWidget);
  });

  testWidgets('tappable item calls back and shows an open indicator', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, WarningListItem(title: 'Title', onTap: () => taps++));

    expect(find.byIcon(Symbols.open_in_new), findsOneWidget);
    await tester.tap(find.text('Title'));
    expect(taps, 1);
  });

  testWidgets('item without a callback has no open indicator', (tester) async {
    await _pump(tester, const WarningListItem(title: 'Title'));
    expect(find.byIcon(Symbols.open_in_new), findsNothing);
  });
}
