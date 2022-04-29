import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/logging.dart';

import '../theme.dart';
import 'state.dart';

class YubicoAuthenticatorApp extends ConsumerWidget {
  final Widget page;
  const YubicoAuthenticatorApp({required this.page, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LogWarningOverlay(
      child: MaterialApp(
        title: 'Yubico Authenticator',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ref.watch(themeModeProvider),
        home: page,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
