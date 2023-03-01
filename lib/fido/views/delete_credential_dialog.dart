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

// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteCredentialDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final FidoCredential credential;
  const DeleteCredentialDialog(this.devicePath, this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final label = credential.userName;

    return ResponsiveDialog(
      title: Text(l10n.l_delete_credential),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_warning_delete_credential),
            Text(l10n.l_credential(label)),
          ]
              .map((e) => Padding(
                    child: e,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(credentialProvider(devicePath).notifier)
                .deleteCredential(credential);
            await ref.read(withContextProvider)(
              (context) async {
                Navigator.of(context).pop(true);
                showMessage(context, l10n.l_credential_deleted);
              },
            );
          },
          child: Text(l10n.w_delete),
        ),
      ],
    );
  }
}
