/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../android/models.dart';
import '../../android/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../desktop/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../version.dart';
import '../../widgets/basic_dialog.dart';
import '../../widgets/info_popup_button.dart';
import '../../widgets/list_title.dart';
import '../../widgets/responsive_dialog.dart';
import '../../widgets/tooltip_if_truncated.dart';
import '../app_url_launcher.dart';
import '../icon_provider/icon_pack.dart';
import '../icon_provider/icon_pack_manager.dart';
import '../l10n_utils.dart';
import '../logging.dart';
import '../message.dart';
import '../models.dart';
import '../shortcuts.dart';
import '../state.dart';
import 'action_list.dart';
import 'app_list_item.dart';
import 'app_page.dart';
import 'keys.dart' as keys;

final _log = Logger('settings');

extension on ThemeMode {
  String getDisplayName(AppLocalizations l10n) => switch (this) {
    ThemeMode.system => l10n.s_system_default,
    ThemeMode.light => l10n.s_light_mode,
    ThemeMode.dark => l10n.s_dark_mode,
  };
}

extension on Locale {
  String getNativeDisplayName() {
    final l10n = lookupAppLocalizations(this);
    return l10n.native_language_name;
  }
}

enum SettingsSection {
  theme(),
  customIcons(),
  language(),
  readers(),
  debugging(),
  help(),
  nfcAndUsb(),
}

class _SettingsSectionItem extends StatelessWidget {
  final SettingsSection item;
  final SettingsSection? selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool expanded;

  const _SettingsSectionItem(
    this.item, {
    required this.selected,
    required this.expanded,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openIntent = OpenIntent<SettingsSection>(item);
    return AppListItem<SettingsSection>(
      item,
      selected: item == selected,
      title: title,
      subtitle: subtitle,
      leading: CircleAvatar(
        foregroundColor: theme.colorScheme.onSecondary,
        backgroundColor: theme.colorScheme.secondary,
        child: Icon(icon),
      ),
      trailing: expanded
          ? null
          : OutlinedButton(
              onPressed: Actions.handler(context, openIntent),
              child: const Icon(Symbols.more_horiz),
            ),
      tapIntent: isDesktop && !expanded ? null : openIntent,
      doubleTapIntent: isDesktop && !expanded ? openIntent : null,
    );
  }
}

class _ThemeModeView extends ConsumerWidget {
  final bool isDialog;
  const _ThemeModeView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final supportedThemes = ref.read(supportedThemesProvider);

    final content = Column(
      children: [
        ListTitle(l10n.s_options),
        ...supportedThemes.map(
          (e) => RadioListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 22),
            title: Transform.translate(
              offset: Offset(4, 0),
              child: Text(e.getDisplayName(l10n)),
            ),
            value: e,
            key: keys.themeModeOption(e),
            groupValue: themeMode,
            toggleable: true,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
                if (isDialog) {
                  Navigator.pop(context, e);
                }
              }
            },
          ),
        ),
      ],
    );
    if (isDialog) {
      return ResponsiveDialog(
        title: Text(l10n.s_app_theme),
        dialogMaxWidth: 400,
        builder: (context, fullScreen) => content,
      );
    } else {
      return content;
    }
  }
}

class _ThemeModeItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _ThemeModeItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    return _SettingsSectionItem(
      SettingsSection.theme,
      selected: selected,
      expanded: expanded,
      title: l10n.s_app_theme,
      icon: Symbols.contrast,
      subtitle: themeMode.getDisplayName(l10n),
    );
  }
}

class _HelpView extends ConsumerWidget {
  final bool isDialog;
  const _HelpView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final itemRadius = isDialog ? 0.0 : null;
    final content = Column(
      children: [
        ListTitle(l10n.s_about),
        Image.asset('assets/graphics/app-icon.png', scale: 1 / 0.75),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Text(
                l10n.app_name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(version),
            ],
          ),
        ),
        ActionListSection(
          null,
          fullWidth: isDialog,
          children: [
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.open_in_new),
              title: l10n.s_terms_of_use,
              onTap: (_) => launchTermsUrl(),
            ),
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.open_in_new),
              title: l10n.s_privacy_policy,
              onTap: (_) => launchPrivacyUrl(),
            ),
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.copyright),
              title: l10n.s_open_src_licenses,
              onTap: (context) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const LicensePage(applicationVersion: version),
                    settings: const RouteSettings(name: 'licenses'),
                  ),
                );
              },
            ),
          ],
        ),
        ActionListSection(
          l10n.s_help,
          fullWidth: isDialog,
          children: [
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.open_in_new),
              title: l10n.s_user_guide,
              onTap: (_) => launchDocumentationUrl(),
            ),
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.open_in_new),
              title: l10n.s_i_need_help,
              onTap: (_) => launchHelpUrl(),
            ),
            if (isDesktop)
              ActionListItem(
                borderRadius: itemRadius,
                icon: Icon(Symbols.keyboard),
                title: l10n.s_keyboard_shortcuts,
                onTap: (context) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Actions.maybeInvoke(context, ShortcutsIntent());
                },
              ),
          ],
        ),
      ],
    );

    return isDialog
        ? ResponsiveDialog(
            title: Text(l10n.s_help_and_about),
            builder: (context, fullScreen) => Padding(
              padding: const EdgeInsets.only(top: 32),
              child: content,
            ),
            dialogMaxWidth: 400,
          )
        : content;
  }
}

class _HelpItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _HelpItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSectionItem(
      SettingsSection.help,
      selected: selected,
      expanded: expanded,
      title: l10n.s_help_and_about,
      icon: Symbols.help,
      subtitle: l10n.s_app_information,
    );
  }
}

class _IconsView extends ConsumerStatefulWidget {
  final bool isDialog;
  const _IconsView({required this.isDialog});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IconsViewState();
}

class _IconsViewState extends ConsumerState<_IconsView> {
  bool _replacing = false;
  Uri get _learnMoreAegisUri => Uri.parse('https://yubi.co/ya-custom-icons');

  Future<void> _importIconPack(
    BuildContext context,
    WidgetRef ref,
    IconPack? iconPack,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['zip'],
      type: FileType.custom,
      allowMultiple: false,
      lockParentWindow: true,
      dialogTitle: l10n.s_choose_icon_pack,
    );
    if (result != null && result.files.isNotEmpty) {
      if (iconPack != null) {
        setState(() {
          _replacing = true;
        });
      }
      final importStatus = await ref
          .read(iconPackProvider.notifier)
          .importPack(l10n, result.paths.first!);
      await ref.read(withContextProvider)((context) async {
        if (importStatus) {
          showMessage(context, l10n.l_icon_pack_imported);
        } else {
          showMessage(
            context,
            l10n.l_import_icon_pack_failed(
              ref.read(iconPackProvider.notifier).lastError ??
                  l10n.l_import_error,
            ),
          );
        }
      });
    }
    setState(() {
      _replacing = false;
    });
  }

  String _getIconPackTitle(IconPack? iconPack, AppLocalizations l10n) {
    return iconPack != null || _replacing
        ? l10n.s_replace_icon_pack
        : l10n.s_load_icon_pack;
  }

  Widget _buildContent(IconPack? iconPack, bool isLoading, bool fullScreen) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionListSection(
          l10n.s_actions,
          fullWidth: widget.isDialog,
          children: [
            ActionListItem(
              borderRadius: widget.isDialog ? 0 : null,
              icon: isLoading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        strokeAlign: 2.0,
                      ),
                    )
                  : const Icon(Symbols.download),
              trailing: InfoPopupButton(
                size: 30,
                iconSize: 20,
                displayDialog: fullScreen,
                infoText: injectLinksInText(
                  // We don't want to translate 'Aegis Icon Pack'
                  l10n.p_custom_icons_format_desc('Aegis Icon Pack'),
                  {'Aegis Icon Pack': _learnMoreAegisUri},
                  linkStyle: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              title: _getIconPackTitle(iconPack, l10n),
              subtitle: isLoading
                  ? 'Loading...'
                  : iconPack != null
                  ? '${iconPack.name} (${iconPack.version})'
                  : 'Load Aegis Icon packs',
              onTap: (context) => _importIconPack(context, ref, iconPack),
            ),
            ActionListItem(
              borderRadius: widget.isDialog ? 0 : null,
              icon: const Icon(Symbols.delete),
              title: 'Remove icon pack', // replace if non-empty
              subtitle: 'Delete the active icon pack',
              onTap: iconPack != null && !isLoading
                  ? (context) async {
                      final removePackStatus = await ref
                          .read(iconPackProvider.notifier)
                          .removePack();
                      await ref.read(withContextProvider)((context) async {
                        if (removePackStatus) {
                          showMessage(context, l10n.l_icon_pack_removed);
                        } else {
                          showMessage(context, l10n.l_remove_icon_pack_failed);
                        }
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconPack = ref
        .watch(iconPackProvider)
        .maybeWhen(data: (data) => data, orElse: () => null);
    final isLoading = ref.watch(iconPackProvider).isLoading;
    return widget.isDialog
        ? ResponsiveDialog(
            title: Text(l10n.s_custom_icons),
            dialogMaxWidth: 400,
            builder: (context, fullScreen) =>
                _buildContent(iconPack, isLoading, fullScreen),
          )
        : _buildContent(iconPack, isLoading, false);
  }
}

class _IconsItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _IconsItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSectionItem(
      SettingsSection.customIcons,
      selected: selected,
      expanded: expanded,
      icon: Symbols.image,
      title: l10n.s_custom_icons,
      subtitle: l10n.l_set_icons_for_accounts,
    );
  }
}

class _LanguageView extends ConsumerWidget {
  final bool isDialog;
  const _LanguageView({required this.isDialog});

  Widget _buildLocaleTitle(
    BuildContext context,
    Locale locale,
    Map<String, LocaleStatus> status,
  ) {
    final localeStatus = status[locale.toString()];
    if (localeStatus == null) {
      return Text(locale.getNativeDisplayName());
    }
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    int translated = localeStatus.translated;
    int proofread = localeStatus.proofread;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(locale.getNativeDisplayName()),
        if (translated != 100 || proofread != 100) ...[
          const SizedBox(width: 8.0),
          InfoPopupButton(
            size: 30,
            iconSize: 20,
            iconColor: (translated == 100 && proofread != 100)
                ? theme.disabledColor
                : theme.colorScheme.tertiary,
            icon: Symbols.info,
            infoText: Text.rich(
              WidgetSpan(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.l_incomplete_translation,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      l10n.s_translated(translated),
                      style: theme.textTheme.labelSmall,
                    ),
                    LinearProgressIndicator(
                      value: translated / 100,
                      trackGap: 0,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      l10n.s_proofread(proofread),
                      style: theme.textTheme.labelSmall,
                    ),
                    LinearProgressIndicator(
                      value: proofread / 100,
                      trackGap: 0,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      l10n.p_translation_progress_desc,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(currentLocaleProvider);
    final supportedLocales = ref.read(supportedLocalesProvider);
    final status = ref.read(localeStatusProvider);
    // Sort locales alphabetically
    supportedLocales.sort(
      (a, b) => a.getNativeDisplayName().compareTo(b.getNativeDisplayName()),
    );

    final itemRadius = isDialog ? 0.0 : null;
    final content = Column(
      children: [
        ListTitle(l10n.s_options),
        ...supportedLocales.map(
          (e) => RadioListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 22),
            title: Transform.translate(
              offset: Offset(4, 0),
              child: _buildLocaleTitle(context, e, status),
            ),
            value: e,
            groupValue: currentLocale,
            toggleable: true,
            onChanged: (value) {
              if (value != null) {
                ref.read(currentLocaleProvider.notifier).setLocale(value);
                if (isDialog) {
                  Navigator.pop(context, e);
                }
              }
            },
          ),
        ),
        ActionListSection(
          l10n.s_community,
          fullWidth: isDialog,
          children: [
            ActionListItem(
              borderRadius: itemRadius,
              icon: Icon(Symbols.open_in_new),
              title: l10n.l_localization_project,
              onTap: (_) => launchCrowdinUrl(),
            ),
          ],
        ),
      ],
    );
    if (isDialog) {
      return ResponsiveDialog(
        title: Text(l10n.s_language),
        dialogMaxWidth: 400,
        builder: (context, fullScreen) => content,
      );
    } else {
      return content;
    }
  }
}

class _LanguageItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _LanguageItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(currentLocaleProvider);
    return _SettingsSectionItem(
      SettingsSection.language,
      selected: selected,
      expanded: expanded,
      icon: Symbols.language,
      title: l10n.s_language,
      subtitle: currentLocale.getNativeDisplayName(),
    );
  }
}

class _ToggleReadersView extends ConsumerWidget {
  final bool isDialog;
  const _ToggleReadersView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hidden = ref.watch(hiddenDevicesProvider);
    final nfcDevices = ref
        .watch(attachedDevicesProvider)
        .where((e) => e.transport == Transport.nfc);
    if (nfcDevices.isEmpty && isDialog) {
      Navigator.of(context).pop();
    }

    final items = nfcDevices.map(
      (e) => SwitchListTile(
        value: !hidden.contains(e.path.key),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 26),
        onChanged: (show) {
          if (!show) {
            ref.read(hiddenDevicesProvider.notifier).hideDevice(e.path);
          } else {
            ref.read(hiddenDevicesProvider.notifier).showDevice(e.path);
          }
        },
        title: Transform.translate(
          offset: Offset(6, 0),
          child: TooltipIfTruncated(
            text: e.name,
            style: TextStyle(fontSize: textTheme.bodyMedium?.fontSize),
          ),
        ),
        secondary: Icon(Symbols.contactless),
      ),
    );
    if (isDialog) {
      return ResponsiveDialog(
        title: Text(l10n.s_toggle_readers),
        builder: (context, fullScreen) => Column(children: [...items]),
      );
    } else {
      return Column(children: [ListTitle(l10n.s_toggle_readers), ...items]);
    }
  }
}

class _ToggleReadersItem extends StatelessWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _ToggleReadersItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSectionItem(
      SettingsSection.readers,
      selected: selected,
      expanded: expanded,
      icon: Symbols.contactless,
      title: l10n.s_toggle_readers,
      subtitle: l10n.l_toggle_readers_desc,
    );
  }
}

class _LogsView extends ConsumerStatefulWidget {
  final bool isDialog;
  const _LogsView({required this.isDialog});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<_LogsView> {
  bool _diagnosing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logLevel = ref.watch(logLevelProvider);
    final tiles = Levels.LEVELS.map(
      (e) => RadioListTile<Level>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.isDialog ? 0 : 48.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 22),
        title: Transform.translate(
          offset: Offset(4, 0),
          child: Text('${e.name[0]}${e.name.substring(1).toLowerCase()}'),
        ),
        value: e,
        groupValue: logLevel,
        toggleable: true,
        onChanged: (value) {
          if (value != null) {
            ref.read(logLevelProvider.notifier).setLogLevel(value);
            if (widget.isDialog) {
              Navigator.pop(context, e);
            }
          }
        },
      ),
    );

    final allowScreenshots = ref.watch(androidAllowScreenshotsProvider);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTitle(l10n.s_logging_level),
        ...tiles,
        ActionListSection(
          l10n.s_actions,
          fullWidth: widget.isDialog,
          children: [
            ActionListItem(
              borderRadius: widget.isDialog ? 0 : null,
              icon: const Icon(Symbols.content_copy),
              title: l10n.s_copy_log,
              subtitle: l10n.l_copy_log_clipboard,
              onTap: (context) async {
                _log.info('Copying log to clipboard ($version)...');
                final logs = await ref
                    .read(logLevelProvider.notifier)
                    .getLogs();
                var clipboard = ref.read(clipboardProvider);
                await clipboard.setText(logs.join('\n'));
                if (!clipboard.platformGivesFeedback()) {
                  await ref.read(withContextProvider)((context) async {
                    showMessage(context, l10n.l_log_copied);
                  });
                }
              },
            ),
            if (isDesktop)
              ActionListItem(
                borderRadius: widget.isDialog ? 0 : null,
                icon: _diagnosing
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          strokeAlign: 2.0,
                        ),
                      )
                    : const Icon(Symbols.bug_report),
                title: l10n.s_run_diagnostics,
                subtitle: l10n.l_run_diagnostics_desc,
                onTap: (context) async {
                  _log.info('Running diagnostics...');
                  setState(() {
                    _diagnosing = true;
                  });
                  final response = await ref
                      .read(rpcProvider)
                      .requireValue
                      .command('diagnose', []);
                  final data = response['diagnostics'] as List;
                  data.insert(0, {
                    'app_version': version,
                    'dart': Platform.version,
                    'os': Platform.operatingSystem,
                    'os_version': Platform.operatingSystemVersion,
                  });
                  data.insert(data.length - 1, ref.read(featureFlagProvider));
                  final text = const JsonEncoder.withIndent('  ').convert(data);
                  await ref.read(clipboardProvider).setText(text);
                  await ref.read(withContextProvider)((context) async {
                    showMessage(context, l10n.l_diagnostics_copied);
                  });
                  setState(() {
                    _diagnosing = false;
                  });
                },
              ),
            if (isAndroid)
              ActionListItem(
                key: keys.allowScreenshotsSetting,
                borderRadius: widget.isDialog ? 0 : null,
                icon: Icon(Symbols.screenshot),
                title: l10n.s_allow_screenshots,
                subtitle: l10n.l_allow_screenshots_desc,
                trailing: Switch(
                  value: allowScreenshots,
                  onChanged: (value) {
                    ref
                        .read(androidAllowScreenshotsProvider.notifier)
                        .setAllowScreenshots(value);
                  },
                ),
                onTap: (context) {
                  ref
                      .read(androidAllowScreenshotsProvider.notifier)
                      .setAllowScreenshots(!allowScreenshots);
                },
              ),
          ],
        ),
      ],
    );

    return widget.isDialog
        ? ResponsiveDialog(
            title: Text(l10n.s_debugging_tools),
            dialogMaxWidth: 400,
            builder: (context, fullScreen) => content,
          )
        : content;
  }
}

class _LogsItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _LogsItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final logLevel = ref.watch(logLevelProvider);
    return _SettingsSectionItem(
      SettingsSection.debugging,
      selected: selected,
      expanded: expanded,
      icon: Symbols.auto_graph,
      title: l10n.s_debugging_tools,
      subtitle: l10n.s_current_log_level(
        logLevel.name[0] + logLevel.name.substring(1).toLowerCase(),
      ),
    );
  }
}

class _NfcTapActionView extends ConsumerWidget {
  final bool isDialog;
  const _NfcTapActionView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tapAction = ref.watch(androidNfcTapActionProvider);
    return Column(
      children: [
        ListTitle(l10n.l_on_yk_nfc_tap),
        ...NfcTapAction.values.map(
          (e) => RadioListTile<NfcTapAction>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 22),
            title: Transform.translate(
              offset: Offset(4, 0),
              child: Text(e.getDescription(l10n)),
            ),
            value: e,
            groupValue: tapAction,
            toggleable: true,
            onChanged: (mode) {
              if (mode != null) {
                ref
                    .read(androidNfcTapActionProvider.notifier)
                    .setTapAction(mode);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _NfcKbdLayoutView extends ConsumerWidget {
  final bool isDialog;
  const _NfcKbdLayoutView({required this.isDialog});

  Future<String?> _selectKbdLayout(
    BuildContext context,
    List<String> available,
    String currentKbdLayout,
  ) async => await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      final l10n = AppLocalizations.of(context);
      return SimpleDialog(
        title: Text(l10n.s_choose_kbd_layout),
        children: available
            .map(
              (e) => RadioListTile<String>(
                title: Text(e),
                value: e,
                toggleable: true,
                groupValue: currentKbdLayout,
                onChanged: (mode) {
                  Navigator.pop(context, e);
                },
              ),
            )
            .toList(),
      );
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tapAction = ref.watch(androidNfcTapActionProvider);
    final clipKbdLayout = ref.watch(androidNfcKbdLayoutProvider);
    return ListTile(
      key: keys.nfcKeyboardLayoutSetting,
      title: Text(l10n.l_kbd_layout_for_static),
      subtitle: Text(clipKbdLayout),
      leading: Icon(Symbols.keyboard),
      enabled:
          tapAction == NfcTapAction.copy ||
          tapAction == NfcTapAction.launchAndCopy,
      onTap: () async {
        final newValue = await _selectKbdLayout(
          context,
          ref.watch(androidNfcSupportedKbdLayoutsProvider),
          clipKbdLayout,
        );
        if (newValue != null) {
          await ref
              .read(androidNfcKbdLayoutProvider.notifier)
              .setKeyboardLayout(newValue);
        }
      },
    );
  }
}

class _NfcBypassTouchView extends ConsumerWidget {
  final bool isDialog;
  const _NfcBypassTouchView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nfcBypassTouch = ref.watch(androidNfcBypassTouchProvider);
    return SwitchListTile(
      key: keys.nfcBypassTouchSetting,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
      ),
      secondary: Icon(Symbols.touch_app),
      title: Text(l10n.l_bypass_touch_requirement),
      subtitle: Text(
        nfcBypassTouch
            ? l10n.l_bypass_touch_requirement_on
            : l10n.l_bypass_touch_requirement_off,
      ),
      value: nfcBypassTouch,
      onChanged: (value) {
        ref
            .read(androidNfcBypassTouchProvider.notifier)
            .setNfcBypassTouch(value);
      },
    );
  }
}

class _NfcSilenceSoundsView extends ConsumerWidget {
  final bool isDialog;
  const _NfcSilenceSoundsView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nfcSilenceSounds = ref.watch(androidNfcSilenceSoundsProvider);
    return SwitchListTile(
      key: keys.nfcSilenceSoundsSettings,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
      ),
      secondary: Icon(Symbols.volume_up),
      title: Text(l10n.s_silence_nfc_sounds),
      subtitle: Text(
        nfcSilenceSounds
            ? l10n.l_silence_nfc_sounds_on
            : l10n.l_silence_nfc_sounds_off,
      ),
      value: nfcSilenceSounds,
      onChanged: (value) {
        ref
            .read(androidNfcSilenceSoundsProvider.notifier)
            .setNfcSilenceSounds(value);
      },
    );
  }
}

class _UsbOpenAppView extends ConsumerWidget {
  final bool isDialog;
  const _UsbOpenAppView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final usbOpenApp = ref.watch(androidUsbLaunchAppProvider);
    return Column(
      children: [
        ListTitle(l10n.l_on_yk_usb_insert),
        SwitchListTile(
          key: keys.usbOpenAppSetting,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDialog ? 0 : 48.0),
          ),
          secondary: Icon(Symbols.usb),
          title: Text(l10n.l_launch_app_on_usb),
          subtitle: Text(
            usbOpenApp
                ? l10n.l_launch_app_on_usb_on
                : l10n.l_launch_app_on_usb_off,
          ),
          value: usbOpenApp,
          onChanged: (value) {
            ref
                .read(androidUsbLaunchAppProvider.notifier)
                .setUsbLaunchApp(value);
          },
        ),
      ],
    );
  }
}

class _NfcAndUsbView extends ConsumerWidget {
  final bool isDialog;
  const _NfcAndUsbView({required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = Column(
      children: [
        if (ref.watch(androidNfcSupportProvider)) ...[
          _NfcTapActionView(isDialog: isDialog),
          _NfcKbdLayoutView(isDialog: isDialog),
          _NfcBypassTouchView(isDialog: isDialog),
          _NfcSilenceSoundsView(isDialog: isDialog),
        ],
        _UsbOpenAppView(isDialog: isDialog),
      ],
    );
    if (isDialog) {
      return ResponsiveDialog(
        title: Text(l10n.s_nfc_and_usb_options),
        dialogMaxWidth: 400,
        builder: (context, fullScreen) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [content],
        ),
      );
    } else {
      return content;
    }
  }
}

class _NfcAndUsbItem extends ConsumerWidget {
  final SettingsSection? selected;
  final bool expanded;
  const _NfcAndUsbItem({required this.selected, required this.expanded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSectionItem(
      SettingsSection.nfcAndUsb,
      selected: selected,
      expanded: expanded,
      icon: Symbols.contactless,
      title: l10n.s_nfc_and_usb_options,
      subtitle: l10n.l_nfc_and_usb_options_desc,
    );
  }
}

class _ConfirmResetDialog extends StatelessWidget {
  const _ConfirmResetDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BasicDialog(
      icon: Icon(Symbols.delete_forever),
      title: Text('Reset settings?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.s_reset),
        ),
      ],
      content: Text(
        'This will restore all settings to their default values.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

Future<bool> confirmReset(BuildContext context) async {
  return await showDialog(
        context: context,
        builder: (context) => _ConfirmResetDialog(),
      ) ??
      false;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  SettingsSection? _selected;

  Widget _buildSectionView(SettingsSection section, bool isDialog) {
    return switch (section) {
      SettingsSection.language => _LanguageView(isDialog: isDialog),
      SettingsSection.theme => _ThemeModeView(isDialog: isDialog),
      SettingsSection.debugging => _LogsView(isDialog: isDialog),
      SettingsSection.readers => _ToggleReadersView(isDialog: isDialog),
      SettingsSection.customIcons => _IconsView(isDialog: isDialog),
      SettingsSection.help => _HelpView(isDialog: isDialog),
      SettingsSection.nfcAndUsb => _NfcAndUsbView(isDialog: isDialog),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    ref.listen(attachedDevicesProvider, (prev, next) {
      final nfcDevices = next.where((e) => e.transport == Transport.nfc);
      if (nfcDevices.isEmpty && _selected == SettingsSection.readers) {
        setState(() {
          _selected = null;
        });
      }
    });
    return Actions(
      actions: {
        EscapeIntent: CallbackAction<EscapeIntent>(
          onInvoke: (intent) {
            if (_selected != null) {
              setState(() {
                _selected = null;
              });
            } else {
              Actions.invoke(context, intent);
            }
            return false;
          },
        ),
      },
      child: AppPage(
        title: l10n.s_settings,
        keyActionsBuilder: _selected == null
            ? (context) {
                return Column(
                  children: [
                    ActionListSection(
                      l10n.s_manage,
                      children: [
                        ActionListItem(
                          icon: Icon(Symbols.delete_forever),
                          title: l10n.s_reset_settings,
                          subtitle: l10n.l_reset_settings_desc,
                          onTap: (context) async {
                            if (!await confirmReset(context)) {
                              return;
                            }
                            // TODO: maybe this should be handled in a notifier
                            await ref.read(prefProvider).clear();
                            // Need to restore current section
                            ref
                                .read(currentSectionProvider.notifier)
                                .setCurrentSection(Section.settings);
                            ref.invalidate(prefProvider);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }
            : null,
        detailViewBuilder: _selected != null
            ? (context) => _buildSectionView(_selected!, false)
            : null,
        builder: (context, expanded) {
          final nfcDevices = ref
              .watch(attachedDevicesProvider)
              .where((e) => e.transport == Transport.nfc);
          return Actions(
            actions: {
              OpenIntent<SettingsSection>:
                  CallbackAction<OpenIntent<SettingsSection>>(
                    onInvoke: (intent) async {
                      if (expanded) {
                        setState(() {
                          _selected = intent.target;
                        });
                      } else {
                        await showBlurDialog(
                          context: context,
                          builder: (context) =>
                              _buildSectionView(intent.target, true),
                        );
                      }
                      return null;
                    },
                  ),
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LanguageItem(selected: _selected, expanded: expanded),
                  if (isAndroid)
                    _NfcAndUsbItem(selected: _selected, expanded: expanded),
                  if (nfcDevices.isNotEmpty && isDesktop)
                    _ToggleReadersItem(selected: _selected, expanded: expanded),
                  const SizedBox(height: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          l10n.s_appearance.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _ThemeModeItem(selected: _selected, expanded: expanded),
                      _IconsItem(selected: _selected, expanded: expanded),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          l10n.s_support.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _LogsItem(selected: _selected, expanded: expanded),
                      _HelpItem(selected: _selected, expanded: expanded),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
