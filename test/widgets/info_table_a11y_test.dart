import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/widgets/info_table.dart';

class _FakeClipboard extends AppClipboard {
  String? lastText;

  @override
  Future<void> setText(String toClipboard, {bool isSensitive = false}) async {
    lastText = toClipboard;
  }

  @override
  bool platformGivesFeedback() => true;
}

void main() {
  testWidgets('InfoTable entries expose tappable semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final clipboard = _FakeClipboard();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clipboardProvider.overrideWithValue(clipboard)],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: InfoTable({'Serial': ('123', UniqueKey())})),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Serial: 123')),
        matchesSemantics(
          label: 'Serial: 123',
          hint: 'Copy to clipboard',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(find.text('123'));
      await tester.pump();
      expect(clipboard.lastText, '123');
    } finally {
      semantics.dispose();
    }
  });
}
