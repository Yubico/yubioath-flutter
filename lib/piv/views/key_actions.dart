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

import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/action_list.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import 'manage_key_dialog.dart';
import 'manage_pin_puk_dialog.dart';

bool pivShowActionsNotifier(PivState state) {
  final usingDefaultPin = state.metadata?.pinMetadata.defaultValue == true;
  final usingDefaultPuk = state.metadata?.pukMetadata.defaultValue == true;
  final usingDefaultMgmtKey =
      state.metadata?.managementKeyMetadata.defaultValue == true;

  return usingDefaultPin || usingDefaultPuk || usingDefaultMgmtKey;
}

Widget pivBuildActions(
  BuildContext context,
  YubiKeyData data,
  PivState pivState,
) {
  final colors =
      Theme.of(context).buttonTheme.colorScheme ??
      Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context);

  final usingDefaultPin = pivState.metadata?.pinMetadata.defaultValue == true;
  final usingDefaultPuk = pivState.metadata?.pukMetadata.defaultValue == true;
  final usingDefaultMgmtKey =
      pivState.metadata?.managementKeyMetadata.defaultValue == true;

  final pinBlocked = pivState.pinAttempts == 0;
  final pukAttempts = pivState.metadata?.pukMetadata.attemptsRemaining;
  final alertIcon = Icon(Symbols.warning_amber, color: colors.tertiary);

  final devicePath = data.node.path;
  final isBio = [
    FormFactor.usbABio,
    FormFactor.usbCBio,
  ].contains(data.info.formFactor);

  return Column(
    children: [
      ActionListSection(
        l10n.s_manage,
        children: [
          ActionListItem(
            key: keys.managePinAction,
            feature: features.actionsPin,
            title: pinBlocked ? l10n.s_unblock_pin : l10n.s_change_pin,
            subtitle: pinBlocked
                ? (pukAttempts != 0
                      ? l10n.l_piv_pin_blocked
                      : l10n.l_piv_pin_puk_blocked)
                : usingDefaultPin
                ? '${l10n.l_attempts_remaining(pivState.pinAttempts)}\n${l10n.l_warning_default_pin}'
                : l10n.l_attempts_remaining(pivState.pinAttempts),
            icon: const Icon(Symbols.pin),
            trailing: pinBlocked || usingDefaultPin ? alertIcon : null,
            onTap: !(pinBlocked && pukAttempts == 0)
                ? (context) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    showBlurDialog(
                      context: context,
                      builder: (context) => ManagePinPukDialog(
                        devicePath,
                        pivState,
                        target: pinBlocked
                            ? ManageTarget.unblock
                            : ManageTarget.pin,
                      ),
                    );
                  }
                : null,
          ),
          if (!isBio)
            ActionListItem(
              key: keys.managePukAction,
              feature: features.actionsPuk,
              title: l10n.s_change_puk,
              subtitle: pukAttempts != null
                  ? (pukAttempts == 0
                        ? l10n.l_piv_pin_puk_blocked
                        : usingDefaultPuk
                        ? '${l10n.l_attempts_remaining(pukAttempts)}\n${l10n.l_warning_default_puk}'
                        : l10n.l_attempts_remaining(pukAttempts))
                  : usingDefaultPuk
                  ? l10n.l_warning_default_puk
                  : null,
              icon: const Icon(Symbols.pin),
              trailing: pukAttempts == 0 || usingDefaultPuk ? alertIcon : null,
              onTap: pukAttempts != 0
                  ? (context) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      showBlurDialog(
                        context: context,
                        builder: (context) => ManagePinPukDialog(
                          devicePath,
                          pivState,
                          target: ManageTarget.puk,
                        ),
                      );
                    }
                  : null,
            ),
          ActionListItem(
            key: keys.manageManagementKeyAction,
            feature: features.actionsManagementKey,
            title: l10n.s_management_key,
            subtitle: usingDefaultMgmtKey
                ? l10n.l_warning_default_key
                : (pivState.protectedKey
                      ? l10n.l_pin_protected_key
                      : l10n.l_change_management_key),
            icon: const Icon(Symbols.key),
            trailing: usingDefaultMgmtKey ? alertIcon : null,
            onTap: (context) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              showBlurDialog(
                context: context,
                builder: (context) => ManageKeyDialog(devicePath, pivState),
              );
            },
          ),
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
                child: const Icon(Symbols.laptop),
              ),
              onTap: () async {
                Navigator.of(context).pop();
              }),
        ],
        */
    ],
  );
}
