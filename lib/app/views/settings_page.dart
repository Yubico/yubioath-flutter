/*
 * Copyright (C) 2022-2023 Yubico.
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

import '../../android/views/settings_views.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import 'keys.dart' as keys;

extension on ThemeMode {
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case ThemeMode.system:
        return l10n.s_system_default;
      case ThemeMode.light:
        return l10n.s_light_mode;
      case ThemeMode.dark:
        return l10n.s_dark_mode;
    }
  }
}

class _ThemeModeView extends ConsumerWidget {
  const _ThemeModeView();

  Future<ThemeMode> _selectAppearance(BuildContext context,
          List<ThemeMode> supportedThemes, ThemeMode themeMode) async =>
      await showDialog<ThemeMode>(
          context: context,
          builder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            return SimpleDialog(
              title: Text(l10n.s_choose_app_theme),
              children: supportedThemes
                  .map((e) => RadioListTile(
                        title: Text(e.getDisplayName(l10n)),
                        value: e,
                        key: keys.themeModeOption(e),
                        groupValue: themeMode,
                        toggleable: true,
                        onChanged: (mode) {
                          Navigator.pop(context, e);
                        },
                      ))
                  .toList(),
            );
          }) ??
      themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    return ListTile(
      title: Text(l10n.s_app_theme),
      subtitle: Text(themeMode.getDisplayName(l10n)),
      key: keys.themeModeSetting,
      onTap: () async {
        final newMode = await _selectAppearance(
            context, ref.read(supportedThemesProvider), themeMode);
        ref.read(themeModeProvider.notifier).setThemeMode(newMode);
      },
    );
  }
}

class _CommunityTranslationsView extends ConsumerWidget {
  const _CommunityTranslationsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enableTranslations = ref.watch(communityTranslationsProvider);
    return SwitchListTile(
        title: Text(l10n.l_enable_community_translations),
        subtitle: Text(l10n.p_community_translations_desc),
        isThreeLine: true,
        value: enableTranslations,
        onChanged: (value) {
          ref
              .read(communityTranslationsProvider.notifier)
              .setEnableCommunityTranslations(value);
        });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
            if (isAndroid) ...[
              ListTitle(l10n.s_nfc_options),
              const NfcTapActionView(),
              const NfcKbdLayoutView(),
              const NfcBypassTouchView(),
              const NfcSilenceSoundsView(),
              ListTitle(l10n.s_usb_options),
              const UsbOpenAppView(),
            ],
            ListTitle(l10n.s_appearance),
            const _ThemeModeView(),
            if (enableTranslations ||
                basicLocaleListResolution(window.locales, officialLocales) !=
                    basicLocaleListResolution(
                        window.locales, AppLocalizations.supportedLocales)) ...[
              ListTitle(l10n.s_language),
              const _CommunityTranslationsView(),
            ],
          ],
        ),
      ),
    );
  }
}
