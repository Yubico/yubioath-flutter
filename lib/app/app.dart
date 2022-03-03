import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state.dart';
import '../theme.dart';
import 'navigation_service.dart';

class YubicoAuthenticatorApp extends ConsumerWidget {
  final Widget page;
  const YubicoAuthenticatorApp({required this.page, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Yubico Authenticator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      home: page,
      debugShowCheckedModeBanner: false,
    );
  }
}
