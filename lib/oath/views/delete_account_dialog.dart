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

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
import 'utils.dart';

class DeleteAccountDialog extends ConsumerWidget {
  final DeviceNode device;
  final OathCredential credential;
  const DeleteAccountDialog(this.device, this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.oath_delete_account),
      actions: [
        TextButton(
          key: keys.deleteButton,
          onPressed: () async {
            try {
              await ref
                  .read(credentialListProvider(device.path).notifier)
                  .deleteAccount(credential);
              await ref.read(withContextProvider)(
                (context) async {
                  Navigator.of(context).pop(true);
                  showMessage(
                      context,
                      AppLocalizations.of(context)!
                          .oath_success_delete_account);
                },
              );
            } on CancellationException catch (_) {
              // ignored
            }
          },
          child: Text(AppLocalizations.of(context)!.oath_delete),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!
                .oath_warning_this_will_delete_account_from_key),
            Text(
              AppLocalizations.of(context)!.oath_warning_disable_this_cred,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
                '${AppLocalizations.of(context)!.oath_account} ${getTextName(credential)}'),
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
}
