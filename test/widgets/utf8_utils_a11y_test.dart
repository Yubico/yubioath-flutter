import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/widgets/utf8_utils.dart';

class _CounterHarness extends StatelessWidget {
  final String value;
  final int maxLength;
  const _CounterHarness({required this.value, required this.maxLength});

  @override
  Widget build(BuildContext context) {
    final counterBuilder = buildByteCounterFor(value);
    return counterBuilder(
          context,
          currentLength: value.length,
          isFocused: true,
          maxLength: maxLength,
        ) ??
        const SizedBox.shrink();
  }
}

void main() {
  testWidgets('Byte counter exposes label and value to Semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: _CounterHarness(value: 'abc', maxLength: 10),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Character count')),
        matchesSemantics(label: 'Character count', value: '3/10'),
      );
    } finally {
      semantics.dispose();
    }
  });
}
