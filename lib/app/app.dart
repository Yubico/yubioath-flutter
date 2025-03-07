/*
 * Copyright (C) 2022,2024 Yubico.
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

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme.dart';
import 'logging.dart';
import 'shortcuts.dart';
import 'state.dart';

class YubicoAuthenticatorApp extends StatelessWidget {
  final Widget page;
  const YubicoAuthenticatorApp({required this.page, super.key});

  @override
  Widget build(BuildContext context) => GlobalShortcuts(
        child: LogWarningOverlay(
          child: Consumer(builder: (context, ref, _) {
            final primaryColor = ref.watch(primaryColorProvider);
            return MaterialApp(
              title: ref.watch(l10nProvider).app_name,
              theme: AppTheme.getLightTheme(primaryColor),
              darkTheme: AppTheme.getDarkTheme(primaryColor),
              themeMode: ref.watch(themeModeProvider),
              home: page,
              debugShowCheckedModeBanner: false,
              locale: ref.watch(currentLocaleProvider),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          }),
        ),
      );
}
