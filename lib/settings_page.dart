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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/message.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_manager.dart';

import 'app/logging.dart';
import 'app/state.dart';
import 'oath/state.dart';
import 'widgets/list_title.dart';
import 'widgets/responsive_dialog.dart';

final _log = Logger('settings');

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);

    final packManager = ref.watch(iconPackManager);
    final hasIconPack = packManager.hasIconPack;

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
            const ListTitle('Account icon pack'),
            ListTile(
              title: hasIconPack ? const Text('Icon pack imported') : const Text('Not using icon pack'),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  hasIconPack ?
                  Row(
                    children: [
                      const Text('Name: ',
                          style: TextStyle(fontSize: 11)),
                      Text('${packManager.iconPackName} (version: ${packManager.iconPackVersion})' ,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                    ],
                  ) : const Text('Tap to import', style: TextStyle(fontSize: 10)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () async{
                  await _showIconPackInfo(context, ref);
                },
              ),
              onTap: () async {
                if (hasIconPack) {
                  await _removeOrChangeIconPack(context, ref);
                } else {
                  await _importIconPack(context, ref);
                }

                await ref.read(withContextProvider)((context) async {
                  ref.invalidate(credentialsProvider);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _importIconPack(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['zip'],
        type: FileType.custom,
        allowMultiple: false,
        lockParentWindow: true,
        dialogTitle: 'Choose icon pack');
    if (result != null && result.files.isNotEmpty) {
      final importStatus =
          await ref.read(iconPackManager).importPack(result.paths.first!);

      await ref.read(withContextProvider)((context) async {
        if (importStatus) {
          showMessage(context, 'Icon pack imported');
        } else {
          showMessage(context, 'Error importing icon pack');
        }
      });
    }

    return false;
  }

  Future<void> _removeOrChangeIconPack(BuildContext context, WidgetRef ref) async =>
      await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              children: [
                ListTile(
                    title: const Text('Replace icon pack'),
                    onTap: () async {
                      await _importIconPack(context, ref);
                      await ref.read(withContextProvider)((context) async {
                        Navigator.pop(context);
                      });
                    }),
                ListTile(
                    title: const Text('Remove icon pack'),
                    onTap: () async {
                      final removePackStatus = await ref.read(iconPackManager).removePack();
                      await ref.read(withContextProvider)(
                            (context) async {
                          if (removePackStatus) {
                            showMessage(context, 'Icon pack removed');
                          } else {
                            showMessage(context, 'Error removing icon pack');
                          }
                          Navigator.pop(context);
                        },
                      );
                    }),
              ],
            );
          });

  Future<void> _showIconPackInfo(BuildContext context, WidgetRef ref) async =>
      await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return const SimpleDialog(
              children: [
                ListTile(
                  title: Text('About icon packs'),
                  subtitle: Text('Icon packs contain icons for accounts. '
                      'To use an icon-pack, download and import one\n\n'
                      'The supported format is aegis-icons.'),
                )
              ],

            );
          });
}
