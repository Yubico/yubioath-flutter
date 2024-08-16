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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/views/action_list.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import 'add_fingerprint_dialog.dart';
import 'enterprise_attestation_dialog.dart';
import 'pin_dialog.dart';

bool passkeysShowActionsNotifier(FidoState state) {
  return (state.alwaysUv && !state.hasPin) || state.forcePinChange;
}

bool fingerprintsShowActionsNotifier(FidoState state) {
  return !state.hasPin || state.bioEnroll == false || state.forcePinChange;
}

Widget passkeysBuildActions(
        BuildContext context, DeviceNode node, FidoState state) =>
    _fidoBuildActions(context, node, state);

Widget fingerprintsBuildActions(BuildContext context, DeviceNode node,
        FidoState state, int fingerprints) =>
    _fidoBuildActions(context, node, state, fingerprints);

Widget _fidoBuildActions(BuildContext context, DeviceNode node, FidoState state,
    [int? fingerprints]) {
  final l10n = AppLocalizations.of(context)!;
  final colors = Theme.of(context).buttonTheme.colorScheme ??
      Theme.of(context).colorScheme;
  final authBlocked = state.pinBlocked;

  final enterpriseAttestation = state.enterpriseAttestation;
  final showEnterpriseAttestation = enterpriseAttestation != null &&
      !(state.alwaysUv && !state.hasPin) &&
      !(!state.unlocked && state.hasPin) &&
      fingerprints == null;
  final canEnableEnterpriseAttestation =
      enterpriseAttestation == false && showEnterpriseAttestation;

  return Column(
    children: [
      if (fingerprints != null)
        ActionListSection(
          l10n.s_setup,
          children: [
            ActionListItem(
              key: keys.addFingerprintAction,
              feature: features.actionsAddFingerprint,
              actionStyle: ActionStyle.primary,
              icon: const Icon(Symbols.fingerprint),
              title: l10n.s_add_fingerprint,
              subtitle: state.unlocked
                  ? l10n.l_fingerprints_used(fingerprints)
                  : state.hasPin
                      ? l10n.l_unlock_pin_first
                      : l10n.l_set_pin_first,
              trailing: fingerprints == 0 || fingerprints == -1
                  ? Icon(Symbols.warning_amber,
                      color: state.unlocked ? colors.tertiary : null)
                  : null,
              onTap: state.unlocked && fingerprints < 5
                  ? (context) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
            key: keys.managePinAction,
            feature: features.actionsPin,
            icon: const Icon(Symbols.pin),
            title: state.hasPin ? l10n.s_change_pin : l10n.s_set_pin,
            subtitle: authBlocked
                ? l10n.l_pin_blocked
                : state.hasPin
                    ? (state.forcePinChange
                        ? l10n.s_pin_change_required
                        : state.pinRetries != null
                            ? l10n.l_attempts_remaining(state.pinRetries!)
                            : l10n.s_fido_pin_protection)
                    : l10n.s_fido_pin_protection,
            trailing: authBlocked ||
                    state.alwaysUv && !state.hasPin ||
                    state.forcePinChange
                ? Icon(Symbols.warning_amber, color: colors.tertiary)
                : null,
            onTap: !authBlocked
                ? (context) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    showBlurDialog(
                      context: context,
                      builder: (context) => FidoPinDialog(node.path, state),
                    );
                  }
                : null,
          ),
          if (showEnterpriseAttestation)
            ActionListItem(
              key: keys.enableEnterpriseAttestation,
              feature: features.enableEnterpriseAttestation,
              icon: const Icon(Symbols.local_police),
              title: l10n.s_ep_attestation,
              subtitle:
                  enterpriseAttestation ? l10n.s_enabled : l10n.s_disabled,
              onTap: canEnableEnterpriseAttestation
                  ? (context) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      showBlurDialog(
                        context: context,
                        builder: (context) =>
                            EnableEnterpriseAttestationDialog(node.path),
                      );
                    }
                  : null,
            )
        ],
      ),
    ],
  );
}
