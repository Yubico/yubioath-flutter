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
  final colors = Theme.of(context).buttonTheme.colorScheme ??
      Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context)!;

  final usingDefaultMgmtKey =
      pivState.metadata?.managementKeyMetadata.defaultValue == true;

  final pinBlocked = pivState.pinAttempts == 0;
  final pukAttempts = pivState.metadata?.pukMetadata.attemptsRemaining;
  final alertIcon = Icon(Icons.warning_amber, color: colors.tertiary);

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
                    ? (pukAttempts != 0
                        ? l10n.l_piv_pin_blocked
                        : l10n.l_piv_pin_puk_blocked)
                    : l10n.l_attempts_remaining(pivState.pinAttempts),
                icon: const Icon(Icons.pin_outlined),
                trailing: pinBlocked ? alertIcon : null,
                onTap: !(pinBlocked && pukAttempts == 0)
                    ? (context) {
                        Navigator.of(context).pop();
                        showBlurDialog(
                          context: context,
                          builder: (context) => ManagePinPukDialog(
                            devicePath,
                            target: pinBlocked
                                ? ManageTarget.unblock
                                : ManageTarget.pin,
                          ),
                        );
                      }
                    : null),
            ActionListItem(
                key: keys.managePukAction,
                title: l10n.s_puk,
                subtitle: pukAttempts != null
                    ? (pukAttempts == 0
                        ? l10n.l_piv_pin_puk_blocked
                        : l10n.l_attempts_remaining(pukAttempts))
                    : null,
                icon: const Icon(Icons.pin_outlined),
                trailing: pukAttempts == 0 ? alertIcon : null,
                onTap: pukAttempts != 0
                    ? (context) {
                        Navigator.of(context).pop();
                        showBlurDialog(
                          context: context,
                          builder: (context) => ManagePinPukDialog(devicePath,
                              target: ManageTarget.puk),
                        );
                      }
                    : null),
            ActionListItem(
                key: keys.manageManagementKeyAction,
                title: l10n.s_management_key,
                subtitle: usingDefaultMgmtKey
                    ? l10n.l_warning_default_key
                    : (pivState.protectedKey
                        ? l10n.l_pin_protected_key
                        : l10n.l_change_management_key),
                icon: const Icon(Icons.key_outlined),
                trailing: usingDefaultMgmtKey ? alertIcon : null,
                onTap: (context) {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => ManageKeyDialog(devicePath, pivState),
                  );
                }),
            ActionListItem(
                key: keys.resetAction,
                icon: const Icon(Icons.delete_outline),
                actionStyle: ActionStyle.error,
                title: l10n.s_reset_piv,
                subtitle: l10n.l_factory_reset_this_app,
                onTap: (context) {
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
