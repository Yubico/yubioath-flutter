/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yubico_authenticator/app/message.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/oath/icon_provider/icon_pack_manager.dart';
import 'package:yubico_authenticator/widgets/responsive_dialog.dart';

class IconPackDialog extends ConsumerWidget {
  const IconPackDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packManager = ref.watch(iconPackManager);
    final hasIconPack = packManager.hasIconPack;
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveDialog(
      title: Text(l10n.oath_custom_icons),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                text: l10n.oath_custom_icons_description,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                children: [_createLearnMoreLink(context, [])],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4.0,
              runSpacing: 8.0,
              children: [
                ActionChip(
                    onPressed: () async {
                      await _importIconPack(context, ref);
                    },
                    avatar: const Icon(Icons.download_outlined, size: 16),
                    label: hasIconPack
                        ? Text(l10n.oath_custom_icons_replace)
                        : Text(l10n.oath_custom_icons_load)),
              ],
            ),
            //const SizedBox(height: 8),
            if (hasIconPack)
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                      fit: FlexFit.loose,
                      child: RichText(
                          text: TextSpan(
                              text: '${packManager.iconPackName}',
                              style: theme.textTheme.bodyMedium,
                              children: [
                            TextSpan(text: ' (${packManager.iconPackVersion})')
                          ]))),
                  Row(
                    children: [
                      IconButton(
                          tooltip: l10n.oath_custom_icons_remove,
                          onPressed: () async {
                            final removePackStatus =
                                await ref.read(iconPackManager).removePack();
                            await ref.read(withContextProvider)(
                              (context) async {
                                if (removePackStatus) {
                                  showMessage(context,
                                      l10n.oath_custom_icons_icon_pack_removed);
                                } else {
                                  showMessage(context,
                                      l10n.oath_custom_icons_err_icon_pack_remove);
                                }
                                // don't close the dialog Navigator.pop(context);
                              },
                            );
                          },
                          icon: const Icon(Icons.delete_outline)),
                      //const SizedBox(width: 8)
                    ],
                  ),
                ],
              ),
          ]
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: e,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<bool> _importIconPack(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['zip'],
        type: FileType.custom,
        allowMultiple: false,
        lockParentWindow: true,
        dialogTitle: l10n.oath_custom_icons_choose_icon_pack);
    if (result != null && result.files.isNotEmpty) {
      final importStatus =
          await ref.read(iconPackManager).importPack(l10n, result.paths.first!);

      await ref.read(withContextProvider)((context) async {
        if (importStatus) {
          showMessage(context, l10n.oath_custom_icons_icon_pack_imported);
        } else {
          showMessage(
              context,
              l10n.oath_custom_icons_err_icon_pack_import(
                  ref.read(iconPackManager).lastError ?? l10n.oath_custom_icons_err_import_general));
        }
      });
    }

    return false;
  }

  TextSpan _createLearnMoreLink(
      BuildContext context, List<InlineSpan>? children) {
    final theme = Theme.of(context);
    return TextSpan(
      text: AppLocalizations.of(context)!.oath_custom_icons_learn_more,
      style: TextStyle(color: theme.colorScheme.primary),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          await launchUrl(
            Uri.parse(
                'https://github.com/Yubico/yubioath-flutter/tree/main/doc'),
            mode: LaunchMode.externalApplication,
          );
        },
      children: children,
    );
  }
}
