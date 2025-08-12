/*
 * Copyright (C) 2023-2025 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'delete_credential_dialog.dart';
import 'delete_fingerprint_dialog.dart';
import 'pin_dialog2.dart';
import 'rename_fingerprint_dialog.dart';

Future<bool> unlockFido(
  BuildContext context,
  WidgetRef ref,
  DevicePath devicePath,
  FidoState state,
) async {
  return await showBlurDialog(
        context: context,
        builder: (context) =>
            FidoPinDialog2(devicePath: devicePath, state: state),
      ) ??
      false;
}

class FidoActions extends ConsumerWidget {
  final DevicePath devicePath;
  final Map<Type, Action<Intent>> Function(BuildContext context)? actions;
  final Widget Function(BuildContext context) builder;

  const FidoActions({
    super.key,
    required this.devicePath,
    this.actions,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withContext = ref.read(withContextProvider);
    final hasFeature = ref.read(featureProvider);

    final fidoState = ref.watch(fidoStateProvider(devicePath)).value;
    final unlocked = fidoState?.unlocked ?? false;

    return Actions(
      actions: {
        if (hasFeature(features.credentialsDelete))
          DeleteIntent<FidoCredential>:
              CallbackAction<DeleteIntent<FidoCredential>>(
                onInvoke: (intent) async {
                  final credential = intent.target;

                  if (!unlocked &&
                      !await withContext(
                        (context) =>
                            unlockFido(context, ref, devicePath, fidoState!),
                      )) {
                    return false;
                  }
                  final deleted = await withContext(
                    (context) => showDialog<bool?>(
                      context: context,
                      builder: (context) =>
                          DeleteCredentialDialog(devicePath, credential),
                    ),
                  );
                  return deleted;
                },
              ),
        if (hasFeature(features.fingerprintsEdit))
          EditIntent<Fingerprint>: CallbackAction<EditIntent<Fingerprint>>(
            onInvoke: (intent) async {
              final fingerprint = intent.target;
              final renamed = await ref.read(withContextProvider)(
                (context) => showBlurDialog<Fingerprint>(
                  context: context,
                  builder: (context) =>
                      RenameFingerprintDialog(devicePath, fingerprint),
                ),
              );
              return renamed;
            },
          ),
        if (hasFeature(features.fingerprintsDelete))
          DeleteIntent<Fingerprint>: CallbackAction<DeleteIntent<Fingerprint>>(
            onInvoke: (intent) async {
              final fingerprint = intent.target;
              final deleted = await ref.read(withContextProvider)(
                (context) => showDialog<bool?>(
                  context: context,
                  builder: (context) =>
                      DeleteFingerprintDialog(devicePath, fingerprint),
                ),
              );
              return deleted;
            },
          ),
      },
      child: Builder(
        // Builder to ensure new scope for actions, they can invoke parent actions
        builder: (context) {
          final child = Builder(builder: builder);
          return actions != null
              ? Actions(actions: actions!(context), child: child)
              : child;
        },
      ),
    );
  }
}

List<ActionItem> buildFingerprintActions(
  Fingerprint fingerprint,
  AppLocalizations l10n,
) {
  return [
    ActionItem(
      key: keys.editFingerprintAction,
      feature: features.fingerprintsEdit,
      icon: const Icon(Symbols.edit),
      title: l10n.s_rename_fp,
      subtitle: l10n.l_rename_fp_desc,
      intent: EditIntent(fingerprint),
    ),
    ActionItem(
      key: keys.deleteFingerprintAction,
      feature: features.fingerprintsDelete,
      actionStyle: ActionStyle.error,
      icon: const Icon(Symbols.delete),
      title: l10n.s_delete_fingerprint,
      subtitle: l10n.l_delete_fingerprint_desc,
      intent: DeleteIntent(fingerprint),
    ),
  ];
}

List<ActionItem> buildCredentialActions(
  FidoCredential credential,
  AppLocalizations l10n,
) {
  return [
    ActionItem(
      key: keys.deleteCredentialAction,
      feature: features.credentialsDelete,
      actionStyle: ActionStyle.error,
      icon: const Icon(Symbols.delete),
      title: l10n.s_delete_passkey,
      subtitle: l10n.l_delete_passkey_desc,
      intent: DeleteIntent(credential),
    ),
  ];
}
