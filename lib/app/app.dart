import 'package:flutter/material.dart';
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
        ),
      ),
    );
  }
}
