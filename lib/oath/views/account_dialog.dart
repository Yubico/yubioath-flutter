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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/action_list.dart';
import '../../app/views/fs_dialog.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/tooltip_if_truncated.dart';
import '../features.dart' as features;
import '../models.dart';
import '../state.dart';
import 'account_helper.dart';
import 'actions.dart';

class AccountDialog extends ConsumerWidget {
  final OathCredential credential;

  const AccountDialog(this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final node = ref.watch(currentDeviceDataProvider).valueOrNull?.node;
    if (node == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final hasFeature = ref.watch(featureProvider);
    final helper = AccountHelper(context, ref, credential);
    final subtitle = helper.subtitle;

    return OathActions(
      devicePath: node.path,
      actions: (context) => {
        if (hasFeature(features.accountsRename))
          EditIntent<OathCredential>:
              CallbackAction<EditIntent<OathCredential>>(
                onInvoke: (intent) async {
                  final renamed =
                      await (Actions.invoke(context, intent)
                          as Future<dynamic>?);
                  if (renamed is OathCredential) {
                    // Replace the dialog with the renamed credential
                    final withContext = ref.read(withContextProvider);
                    await withContext((context) async {
                      Navigator.of(context).pop();
                      await showBlurDialog(
                        context: context,
                        builder: (context) {
                          return AccountDialog(renamed);
                        },
                      );
                    });
                  }
                  return renamed;
                },
              ),
        if (hasFeature(features.accountsDelete))
          DeleteIntent<OathCredential>:
              CallbackAction<DeleteIntent<OathCredential>>(
                onInvoke: (intent) async {
                  final deleted =
                      await (Actions.invoke(context, intent)
                          as Future<dynamic>?);
                  // Pop the account dialog if deleted
                  if (deleted == true) {
                    await ref.read(withContextProvider)((context) async {
                      Navigator.of(context).pop();
                    });
                  }
                  return deleted;
                },
              ),
      },
      builder: (context) {
        if (helper.code == null &&
            (isDesktop || node.transport == Transport.usb)) {
          Timer.run(() {
            // Only call if credential hasn't been deleted/renamed
            if (ref.read(credentialsProvider)?.contains(credential) == true) {
              Actions.invoke(
                context,
                RefreshIntent<OathCredential>(credential),
              );
            }
          });
        }
        return ItemShortcuts(
          item: credential,
          child: FocusScope(
            autofocus: true,
            child: FsDialog(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisSize: .min,
                            crossAxisAlignment: .center,
                            children: [
                              IconTheme(
                                data: IconTheme.of(context).copyWith(size: 24),
                                child: helper.buildCodeIcon(),
                              ),
                              const SizedBox(width: 8.0),
                              DefaultTextStyle.merge(
                                style: const TextStyle(fontSize: 28),
                                child: helper.buildCodeLabel(),
                              ),
                            ],
                          ),
                        ),
                        TooltipIfTruncated(
                          text: helper.title,
                          style: TextStyle(
                            fontSize: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
                        if (subtitle != null)
                          TooltipIfTruncated(
                            text: subtitle,
                            // This is what ListTile uses for subtitle
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  ActionListSection.fromMenuActions(
                    context,
                    AppLocalizations.of(context).s_actions,
                    actions: helper.buildActions(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
