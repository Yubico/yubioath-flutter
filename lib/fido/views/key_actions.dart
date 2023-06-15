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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/fs_dialog.dart';
import '../../app/views/action_list.dart';
import '../models.dart';
import 'add_fingerprint_dialog.dart';
import 'pin_dialog.dart';
import 'reset_dialog.dart';

bool fidoShowActionsNotifier(FidoState state) {
  return (state.alwaysUv && !state.hasPin) || state.bioEnroll == false;
}

Widget fidoBuildActions(
    BuildContext context, DeviceNode node, FidoState state, int fingerprints) {
  final l10n = AppLocalizations.of(context)!;

  return FsDialog(
    child: Column(
      children: [
        if (state.bioEnroll != null)
          ActionListSection(
            l10n.s_setup,
            children: [
              ActionListItem(
                actionStyle: ActionStyle.primary,
                icon: const Icon(Icons.fingerprint_outlined),
                title: l10n.s_add_fingerprint,
                subtitle: state.unlocked
                    ? l10n.l_fingerprints_used(fingerprints)
                    : state.hasPin
                        ? l10n.l_unlock_pin_first
                        : l10n.l_set_pin_first,
                trailing:
                    fingerprints == 0 ? const Icon(Icons.warning_amber) : null,
                onTap: state.unlocked && fingerprints < 5
                    ? (context) {
                        Navigator.of(context).pop();
                        showBlurDialog(
                          context: context,
                          builder: (context) => AddFingerprintDialog(node.path),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ActionListSection(
          l10n.s_manage,
          children: [
            ActionListItem(
                icon: const Icon(Icons.pin_outlined),
                title: state.hasPin ? l10n.s_change_pin : l10n.s_set_pin,
                subtitle: state.hasPin
                    ? l10n.s_fido_pin_protection
                    : l10n.l_fido_pin_protection_optional,
                trailing: state.alwaysUv && !state.hasPin
                    ? const Icon(Icons.warning_amber)
                    : null,
                onTap: (context) {
                  Navigator.of(context).pop();
                  showBlurDialog(
                    context: context,
                    builder: (context) => FidoPinDialog(node.path, state),
                  );
                }),
            ActionListItem(
              actionStyle: ActionStyle.error,
              icon: const Icon(Icons.delete_outline),
              title: l10n.s_reset_fido,
              subtitle: l10n.l_factory_reset_this_app,
              onTap: (context) {
                Navigator.of(context).pop();
                showBlurDialog(
                  context: context,
                  builder: (context) => ResetDialog(node),
                );
              },
            ),
          ],
        )
      ],
    ),
  );
}
