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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../android/state.dart';
import '../../android/views/settings_views.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';
import '../icon_provider/icon_pack_dialog.dart';
import '../models.dart';
import '../state.dart';
import 'keys.dart' as keys;

extension on ThemeMode {
  String getDisplayName(AppLocalizations l10n) => switch (this) {
        ThemeMode.system => l10n.s_system_default,
        ThemeMode.light => l10n.s_light_mode,
        ThemeMode.dark => l10n.s_dark_mode
      };
}

extension on Locale {
  String getDisplayName(AppLocalizations l10n) => switch (languageCode) {
        'en' => l10n.s_english,
        'de' => l10n.s_german,
        'fr' => l10n.s_french,
        'ja' => l10n.s_japanese,
        'pl' => l10n.s_polish,
        'sk' => l10n.s_slovak,
        'vi' => l10n.s_vietnamese,
        _ => languageCode
      };
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

class _LanguageView extends ConsumerWidget {
  const _LanguageView();

  void _selectLocale(
    BuildContext context,
    WidgetRef ref,
    AppLocale currentLocale,
  ) async {
    final groupValue =
        currentLocale.systemDefault ? null : currentLocale.locale;
    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SimpleDialog(
          title: Text('Choose language'),
          children: [
            RadioListTile(
              title: Text(l10n.s_system_default),
              value: null,
              groupValue: groupValue,
              toggleable: true,
              onChanged: (_) {
                ref.read(currentLocaleProvider.notifier).resetLocale();
                Navigator.pop(context);
              },
            ),
            ...AppLocalizations.supportedLocales.map(
              (e) => RadioListTile(
                title: Text(e.getDisplayName(l10n)),
                value: e,
                groupValue: groupValue,
                toggleable: true,
                onChanged: (value) {
                  ref.read(currentLocaleProvider.notifier).setLocale(e);
                  Navigator.pop(context);
                },
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(currentLocaleProvider);
    return ListTile(
      title: Text(l10n.s_language),
      subtitle: Text(currentLocale.locale.getDisplayName(l10n)),
      key: keys.languageSetting,
      onTap: () => _selectLocale(context, ref, currentLocale),
    );
  }
}

class _IconsView extends ConsumerWidget {
  const _IconsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(l10n.s_custom_icons),
      subtitle: Text(l10n.l_set_icons_for_accounts),
      onTap: () {
        showDialog(
          context: context,
          routeSettings: const RouteSettings(name: 'icon_pack_dialog'),
          builder: (context) => const IconPackDialog(),
        );
      },
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveDialog(
      title: Text(l10n.s_settings),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // add nfc options only on devices with NFC capability
          if (isAndroid && ref.watch(androidNfcSupportProvider)) ...[
            ListTitle(l10n.s_nfc_options),
            const NfcTapActionView(),
            const NfcKbdLayoutView(),
            const NfcBypassTouchView(),
            const NfcSilenceSoundsView(),
          ],
          if (isAndroid) ...[
            ListTitle(l10n.s_usb_options),
            const UsbOpenAppView(),
          ],
          ListTitle(l10n.s_appearance),
          const _ThemeModeView(),
          const _IconsView(),
          ListTitle(l10n.s_options),
          const _LanguageView()
        ],
      ),
    );
  }
}
