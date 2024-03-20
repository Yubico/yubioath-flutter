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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../features.dart' as features;
import '../keys.dart' as keys;
import '../models.dart';
import '../state.dart';
import 'authentication_dialog.dart';
import 'delete_certificate_dialog.dart';
import 'generate_key_dialog.dart';
import 'import_file_dialog.dart';
import 'move_key_dialog.dart';
import 'pin_dialog.dart';

class GenerateIntent extends Intent {
  final PivSlot slot;
  const GenerateIntent(this.slot);
}

class ImportIntent extends Intent {
  final PivSlot slot;
  const ImportIntent(this.slot);
}

class ExportIntent extends Intent {
  final PivSlot slot;
  const ExportIntent(this.slot);
}

class MoveIntent extends Intent {
  final PivSlot slot;
  const MoveIntent(this.slot);
}

Future<bool> _authIfNeeded(BuildContext context, WidgetRef ref,
    DevicePath devicePath, PivState pivState) async {
  if (pivState.needsAuth) {
    if (pivState.protectedKey &&
        pivState.metadata?.pinMetadata.defaultValue == true) {
      return await ref
          .read(pivStateProvider(devicePath).notifier)
          .verifyPin(defaultPin) is PinSuccess;
    }
    return await showBlurDialog(
          context: context,
          builder: (context) => pivState.protectedKey
              ? PinDialog(devicePath)
              : AuthenticationDialog(
                  devicePath,
                  pivState,
                ),
        ) ??
        false;
  }
  return true;
}

class PivActions extends ConsumerWidget {
  final DevicePath devicePath;
  final PivState pivState;
  final Map<Type, Action<Intent>> Function(BuildContext context)? actions;
  final Widget Function(BuildContext context) builder;
  const PivActions(
      {super.key,
      required this.devicePath,
      required this.pivState,
      this.actions,
      required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withContext = ref.read(withContextProvider);
    final hasFeature = ref.read(featureProvider);

    return Actions(
      actions: {
        if (hasFeature(features.slotsGenerate))
          GenerateIntent:
              CallbackAction<GenerateIntent>(onInvoke: (intent) async {
            //Verify management key and maybe PIN
            if (!await withContext((context) =>
                _authIfNeeded(context, ref, devicePath, pivState))) {
              return false;
            }
            // Verify PIN, unless already done above
            // TODO: Avoid asking for PIN if not needed?
            if (!pivState.protectedKey) {
              bool verified;
              if (pivState.metadata?.pinMetadata.defaultValue == true) {
                verified = await ref
                    .read(pivStateProvider(devicePath).notifier)
                    .verifyPin(defaultPin) is PinSuccess;
              } else {
                verified = await withContext((context) async =>
                        await showBlurDialog(
                            context: context,
                            builder: (context) => PinDialog(devicePath))) ??
                    false;
              }

              if (!verified) {
                return false;
              }
            }

            return await withContext((context) async {
              final l10n = AppLocalizations.of(context)!;
              final PivGenerateResult? result = await showBlurDialog(
                context: context,
                builder: (context) => GenerateKeyDialog(
                  devicePath,
                  pivState,
                  intent.slot,
                ),
              );

              if (result != null) {
                final (fileExt, title, data) = switch (result.generateType) {
                  GenerateType.publicKey => (
                      'pem',
                      l10n.l_export_public_key_file,
                      result.publicKey,
                    ),
                  GenerateType.csr => (
                      'csr',
                      l10n.l_export_csr_file,
                      result.result,
                    ),
                  _ => (null, null, null),
                };

                if (fileExt != null) {
                  final filePath = await FilePicker.platform.saveFile(
                    dialogTitle: title,
                    allowedExtensions: [fileExt],
                    type: FileType.custom,
                    lockParentWindow: true,
                  );
                  if (filePath != null) {
                    final file = File(filePath);
                    await file.writeAsString(data!, flush: true);
                  }
                }
              }

              return result != null;
            });
          }),
        if (hasFeature(features.slotsImport))
          ImportIntent: CallbackAction<ImportIntent>(onInvoke: (intent) async {
            if (!await withContext((context) =>
                _authIfNeeded(context, ref, devicePath, pivState))) {
              return false;
            }

            final picked = await withContext(
              (context) async {
                final l10n = AppLocalizations.of(context)!;
                return await FilePicker.platform.pickFiles(
                    allowedExtensions: [
                      'pem',
                      'der',
                      'pfx',
                      'p12',
                      'key',
                      'crt'
                    ],
                    type: FileType.custom,
                    allowMultiple: false,
                    lockParentWindow: true,
                    dialogTitle: l10n.l_select_import_file);
              },
            );
            if (picked == null || picked.files.isEmpty) {
              return false;
            }

            return await withContext((context) async =>
                await showBlurDialog(
                  context: context,
                  builder: (context) => ImportFileDialog(
                    devicePath,
                    pivState,
                    intent.slot,
                    File(picked.paths.first!),
                  ),
                ) ??
                false);
          }),
        if (hasFeature(features.slotsExport))
          ExportIntent: CallbackAction<ExportIntent>(onInvoke: (intent) async {
            final l10n = AppLocalizations.of(context)!;
            final (metadata, cert) = await ref
                .read(pivSlotsProvider(devicePath).notifier)
                .read(intent.slot.slot);

            String title;
            String message;
            String data;
            if (cert != null) {
              title = l10n.l_export_certificate_file;
              message = l10n.l_certificate_exported;
              data = cert;
            } else if (metadata != null) {
              title = l10n.l_export_public_key_file;
              message = l10n.l_public_key_exported;
              data = metadata.publicKey;
            } else {
              return false;
            }

            final filePath = await withContext((context) async {
              return await FilePicker.platform.saveFile(
                dialogTitle: title,
                allowedExtensions: ['pem'],
                type: FileType.custom,
                lockParentWindow: true,
              );
            });

            if (filePath == null) {
              return false;
            }

            final file = File(filePath);
            await file.writeAsString(data, flush: true);

            await withContext((context) async {
              showMessage(context, message);
            });
            return true;
          }),
        if (hasFeature(features.slotsDelete))
          DeleteIntent<PivSlot>:
              CallbackAction<DeleteIntent<PivSlot>>(onInvoke: (intent) async {
            if (!await withContext((context) =>
                _authIfNeeded(context, ref, devicePath, pivState))) {
              return false;
            }

            final bool? deleted = await withContext((context) async =>
                await showBlurDialog(
                  context: context,
                  builder: (context) => DeleteCertificateDialog(
                    devicePath,
                    pivState,
                    intent.target,
                  ),
                ) ??
                false);
            return deleted;
          }),
        if (hasFeature(features.slotsMove))
          MoveIntent: CallbackAction<MoveIntent>(onInvoke: (intent) async {
            if (!await withContext((context) =>
                _authIfNeeded(context, ref, devicePath, pivState))) {
              return false;
            }

            final bool? moved = await withContext((context) async =>
                await showBlurDialog(
                  context: context,
                  builder: (context) => MoveKeyDialog(
                    devicePath,
                    pivState,
                    intent.slot,
                  ),
                ) ??
                false);
            return moved;
          }),
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

List<ActionItem> buildSlotActions(
    PivState pivState, PivSlot slot, AppLocalizations l10n) {
  final hasCert = slot.certInfo != null;
  final hasKey = slot.metadata != null;
  final canDeleteOrMoveKey = hasKey && pivState.version.isAtLeast(5, 7);
  return [
    if (!slot.slot.isRetired) ...[
      ActionItem(
        key: keys.generateAction,
        feature: features.slotsGenerate,
        icon: const Icon(Symbols.add),
        actionStyle: ActionStyle.primary,
        title: l10n.s_generate_key,
        subtitle: l10n.l_generate_desc,
        intent: GenerateIntent(slot),
      ),
      ActionItem(
        key: keys.importAction,
        feature: features.slotsImport,
        icon: const Icon(Symbols.file_download),
        title: l10n.l_import_file,
        subtitle: l10n.l_import_desc,
        intent: ImportIntent(slot),
      ),
    ],
    if (hasCert) ...[
      ActionItem(
        key: keys.exportAction,
        feature: features.slotsExport,
        icon: const Icon(Symbols.file_upload),
        title: l10n.l_export_certificate,
        subtitle: l10n.l_export_certificate_desc,
        intent: ExportIntent(slot),
      ),
    ] else if (hasKey) ...[
      ActionItem(
        key: keys.exportAction,
        feature: features.slotsExport,
        icon: const Icon(Symbols.file_upload),
        title: l10n.l_export_public_key,
        subtitle: l10n.l_export_public_key_desc,
        intent: ExportIntent(slot),
      ),
    ],
    if (canDeleteOrMoveKey)
      ActionItem(
        key: keys.moveAction,
        feature: features.slotsMove,
        actionStyle: ActionStyle.error,
        icon: const Icon(Symbols.move_item),
        title: l10n.l_move_key,
        subtitle: l10n.l_move_key_desc,
        intent: MoveIntent(slot),
      ),
    if (hasCert || canDeleteOrMoveKey)
      ActionItem(
        key: keys.deleteAction,
        feature: features.slotsDelete,
        actionStyle: ActionStyle.error,
        icon: const Icon(Symbols.delete),
        title: hasCert && canDeleteOrMoveKey
            ? l10n.l_delete_certificate_or_key
            : hasCert
                ? l10n.l_delete_certificate
                : l10n.l_delete_key,
        subtitle: hasCert && canDeleteOrMoveKey
            ? l10n.l_delete_certificate_or_key_desc
            : hasCert
                ? l10n.l_delete_certificate_desc
                : l10n.l_delete_key_desc,
        intent: DeleteIntent(slot),
      ),
  ];
}
