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
import '../../app/views/action_list.dart';
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
        ActionListSection(
          l10n.s_manage,
          children: [
            ActionListItem(
                key: keys.managePinAction,
                title: l10n.s_pin,
                subtitle: pinBlocked
                    ? l10n.l_piv_pin_blocked
                    : l10n.l_attempts_remaining(pivState.pinAttempts),
                icon: const Icon(Icons.pin_outlined),
                onTap: () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => ManagePinPukDialog(
                      devicePath,
                      target:
                          pinBlocked ? ManageTarget.unblock : ManageTarget.pin,
                    ),
                  );
                }),
            ActionListItem(
                key: keys.managePukAction,
                title: l10n.s_puk,
                subtitle: pukAttempts != null
                    ? l10n.l_attempts_remaining(pukAttempts)
                    : null,
                icon: const Icon(Icons.pin_outlined),
                onTap: () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => ManagePinPukDialog(devicePath,
                        target: ManageTarget.puk),
                  );
                }),
            ActionListItem(
                key: keys.manageManagementKeyAction,
                title: l10n.s_management_key,
                subtitle: usingDefaultMgmtKey
                    ? l10n.l_warning_default_key
                    : (pivState.protectedKey
                        ? l10n.l_pin_protected_key
                        : l10n.l_change_management_key),
                icon: const Icon(Icons.key_outlined),
                trailing: usingDefaultMgmtKey
                    ? const Icon(Icons.warning_amber)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => ManageKeyDialog(devicePath, pivState),
                  );
                }),
            ActionListItem(
                key: keys.resetAction,
                title: l10n.s_reset_piv,
                subtitle: l10n.l_factory_reset_this_app,
                foregroundColor: theme.onError,
                backgroundColor: theme.error,
                icon: const Icon(Icons.delete_outline),
                onTap: () {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => ResetDialog(devicePath),
                  );
                })
          ],
        ),
        // TODO
        /*
          if (false == true) ...[
            KeyActionTitle(l10n.s_setup),
            KeyActionItem(
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
