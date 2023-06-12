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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../models.dart';
import '../state.dart';
import 'account_helper.dart';
import 'actions.dart';
import 'delete_account_dialog.dart';
import 'rename_account_dialog.dart';

class AccountDialog extends ConsumerWidget {
  final OathCredential credential;

  const AccountDialog(this.credential, {super.key});

  List<ActionListItem> _buildActions(
      BuildContext context, AccountHelper helper) {
    final l10n = AppLocalizations.of(context)!;
    final actions = helper.buildActions();

    final copy =
        actions.firstWhere(((e) => e.text == l10n.l_copy_to_clipboard));
    final delete = actions.firstWhere(((e) => e.text == l10n.s_delete_account));
    final canCopy = copy.intent != null;
    final actionStyles = {
      copy: canCopy ? ActionStyle.primary : ActionStyle.normal,
      delete: ActionStyle.error,
    };

    // If we can't copy, but can calculate, highlight that button instead
    if (!canCopy) {
      final calculates = actions.where(((e) => e.text == l10n.s_calculate));
      if (calculates.isNotEmpty) {
        actionStyles[calculates.first] = ActionStyle.primary;
      }
    }

    return actions.map((e) {
      final intent = e.intent;
      return ActionListItem(
        actionStyle: actionStyles[e] ?? ActionStyle.normal,
        icon: e.icon,
        title: e.text,
        subtitle: e.trailing,
        onTap: intent != null
            ? () {
                Actions.invoke(context, intent);
              }
            : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Solve this in a cleaner way
    final node = ref.watch(currentDeviceDataProvider).valueOrNull?.node;
    if (node == null) {
      // The rest of this method assumes there is a device, and will throw an exception if not.
      // This will never be shown, as the dialog will be immediately closed
      return const SizedBox();
    }

    final helper = AccountHelper(context, ref, credential);
    final subtitle = helper.subtitle;

    return registerOathActions(
      credential,
      ref: ref,
      actions: {
        EditIntent: CallbackAction<EditIntent>(onInvoke: (_) async {
          final credentials = ref.read(credentialsProvider);
          final withContext = ref.read(withContextProvider);
          final OathCredential? renamed =
              await withContext((context) async => await showBlurDialog(
                    context: context,
                    builder: (context) => RenameAccountDialog(
                      node,
                      credential,
                      credentials,
                    ),
                  ));
          if (renamed != null) {
            // Replace the dialog with the renamed credential
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
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          final withContext = ref.read(withContextProvider);
          final bool? deleted =
              await ref.read(withContextProvider)((context) async =>
                  await showBlurDialog(
                    context: context,
                    builder: (context) => DeleteAccountDialog(
                      node,
                      credential,
                    ),
                  ) ??
                  false);

          // Pop the account dialog if deleted
          if (deleted == true) {
            await withContext((context) async {
              Navigator.of(context).pop();
            });
          }
          return deleted;
        }),
      },
      builder: (context) {
        if (helper.code == null &&
            (isDesktop || node.transport == Transport.usb)) {
          Timer.run(() {
            // Only call if credential hasn't been deleted/renamed
            if (ref.read(credentialsProvider)?.contains(credential) == true) {
              Actions.invoke(context, const CalculateIntent());
            }
          });
        }
        return FocusScope(
          autofocus: true,
          child: FsDialog(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48, bottom: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                Text(
                  helper.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    // This is what ListTile uses for subtitle
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).textTheme.bodySmall!.color,
                        ),
                  ),
                const SizedBox(height: 32),
                ActionListSection(
                  AppLocalizations.of(context)!.s_actions,
                  children: _buildActions(context, helper),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
