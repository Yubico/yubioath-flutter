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

    return ResponsiveDialog(
      title: const Text('Custom icons'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Icon packs can make your accounts more easily '
                    'distinguishable with familiar logos and colors. ',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
                    label: const Text('Load icon pack')),
                if (hasIconPack)
                  ActionChip(
                      onPressed: () async {
                        final removePackStatus =
                            await ref.read(iconPackManager).removePack();
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
                      },
                      avatar: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove icon pack'))
              ],
            ),
            const SizedBox(height: 8),
            if (hasIconPack)
              Text(
                'Current: ${packManager.iconPackName} (version: ${packManager.iconPackVersion})',
                style: TextStyle(fontSize: 11, color: theme.disabledColor),
              )
            else
              const Text('')
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
          showMessage(context,
              'Error importing icon pack: ${ref.read(iconPackManager).lastError}');
        }
      });
    }

    return false;
  }

  TextSpan _createLearnMoreLink(
      BuildContext context, List<InlineSpan>? children) {
    final theme = Theme.of(context);
    return TextSpan(
      text: 'Learn\u00a0more',
      style: TextStyle(color: theme.primaryColor),
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
