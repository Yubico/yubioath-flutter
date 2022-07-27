import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import 'logging.dart';
import 'shortcuts.dart';
import 'state.dart';

class YubicoAuthenticatorApp extends ConsumerWidget {
  final Widget page;
  const YubicoAuthenticatorApp({required this.page, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LogWarningOverlay(
      child: Shortcuts(
        shortcuts: globalShortcuts,
        child: MaterialApp(
          title: 'Yubico Authenticator',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ref.watch(themeModeProvider),
          home: page,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
        ),
      ),
    );
  }
}
