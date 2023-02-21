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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_settings.dart';

import 'app/logging.dart';
import 'app/state.dart';
import 'widgets/list_title.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);

    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.general_settings),
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
            ListTitle(AppLocalizations.of(context)!.general_appearance),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.general_system_default),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.general_light_mode),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.of(context)!.general_dark_mode),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (mode) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode!);
                _log.debug('Set theme mode to $mode');
              },
            ),
            const IconPackSettings()
          ],
        ),
      ),
    );
  }
}
