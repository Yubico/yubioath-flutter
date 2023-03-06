/*
 * Copyright (C) 2022 Yubico.
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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app/logging.dart';
import 'app/state.dart';
import 'widgets/list_title.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);
    final enableTranslations = ref.watch(communityTranslationsProvider);
    return ResponsiveDialog(
      title: Text(l10n.s_settings),
      child: Theme(
        // Make the headers use the primary color to pop a bit.
        // Once M3 is implemented this will probably not be needed.
        data: theme.copyWith(
          textTheme: theme.textTheme.copyWith(
              labelLarge: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTitle(l10n.s_appearance),
            RadioListTile<ThemeMode>(
              title: Text(l10n.s_system_default),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.s_light_mode),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.s_dark_mode),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            if (enableTranslations ||
                basicLocaleListResolution(window.locales, officialLocales) !=
                    basicLocaleListResolution(
                        window.locales, AppLocalizations.supportedLocales)) ...[
              ListTitle(l10n.s_language),
              SwitchListTile(
                  title: Text(l10n.l_enable_community_translations),
                  subtitle: Text(l10n.p_community_translations_desc),
                  isThreeLine: true,
                  value: enableTranslations,
                  onChanged: (value) {
                    ref
                        .read(communityTranslationsProvider.notifier)
                        .setEnableCommunityTranslations(value);
                  }),
            ],
          ],
        ),
      ),
    );
  }
}
