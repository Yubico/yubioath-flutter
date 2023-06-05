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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/fs_dialog.dart';
import '../../widgets/list_title.dart';
import '../models.dart';
import '../keys.dart' as keys;
import 'manage_key_dialog.dart';
import 'manage_pin_puk_dialog.dart';
import 'reset_dialog.dart';

Widget pivBuildActions(BuildContext context, DevicePath devicePath,
    PivState pivState, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final theme =
      ButtonTheme.of(context).colorScheme ?? Theme.of(context).colorScheme;

  final usingDefaultMgmtKey =
      pivState.metadata?.managementKeyMetadata.defaultValue == true;

  final pinBlocked = pivState.pinAttempts == 0;
  final pukAttempts = pivState.metadata?.pukMetadata.attemptsRemaining;

  return FsDialog(
    child: Column(
      children: [
        ListTitle(l10n.s_manage,
            textStyle: Theme.of(context).textTheme.bodyLarge),
        ListTile(
            key: keys.managePinAction,
            title: Text(l10n.s_pin),
            subtitle: Text(pinBlocked
                ? l10n.l_piv_pin_blocked
                : l10n.l_attempts_remaining(pivState.pinAttempts)),
            leading: CircleAvatar(
              foregroundColor: theme.onSecondary,
              backgroundColor: theme.secondary,
              child: const Icon(Icons.pin_outlined),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) => ManagePinPukDialog(
                  devicePath,
                  target: pinBlocked ? ManageTarget.unblock : ManageTarget.pin,
                ),
              );
            }),
        ListTile(
            key: keys.managePukAction,
            title: Text(l10n.s_puk),
            subtitle: pukAttempts != null
                ? Text(l10n.l_attempts_remaining(pukAttempts))
                : null,
            leading: CircleAvatar(
              foregroundColor: theme.onSecondary,
              backgroundColor: theme.secondary,
              child: const Icon(Icons.pin_outlined),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) =>
                    ManagePinPukDialog(devicePath, target: ManageTarget.puk),
              );
            }),
        ListTile(
            key: keys.manageManagementKeyAction,
            title: Text(l10n.s_management_key),
            subtitle: Text(usingDefaultMgmtKey
                ? l10n.l_warning_default_key
                : (pivState.protectedKey
                    ? l10n.l_pin_protected_key
                    : l10n.l_change_management_key)),
            leading: CircleAvatar(
              foregroundColor: theme.onSecondary,
              backgroundColor: theme.secondary,
              child: const Icon(Icons.key_outlined),
            ),
            trailing:
                usingDefaultMgmtKey ? const Icon(Icons.warning_amber) : null,
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) => ManageKeyDialog(devicePath, pivState),
              );
            }),
        ListTile(
            key: keys.resetAction,
            title: Text(l10n.s_reset_piv),
            subtitle: Text(l10n.l_factory_reset_this_app),
            leading: CircleAvatar(
              foregroundColor: theme.onError,
              backgroundColor: theme.error,
              child: const Icon(Icons.delete_outline),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showBlurDialog(
                context: context,
                builder: (context) => ResetDialog(devicePath),
              );
            }),
        // TODO
        /*
        if (false == true) ...[
          ListTitle(l10n.s_setup,
              textStyle: Theme.of(context).textTheme.bodyLarge),
          ListTile(
              key: keys.setupMacOsAction,
              title: Text('Setup for macOS'),
              subtitle: Text('Create certificates for macOS login'),
              leading: CircleAvatar(
                backgroundColor: theme.secondary,
                foregroundColor: theme.onSecondary,
                child: const Icon(Icons.laptop),
              ),
              onTap: () async {
                Navigator.of(context).pop();
              }),
        ],
        */
      ],
    ),
  );
}
