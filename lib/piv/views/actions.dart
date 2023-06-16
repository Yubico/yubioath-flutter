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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../../app/models.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;
import 'authentication_dialog.dart';
import 'delete_certificate_dialog.dart';
import 'generate_key_dialog.dart';
import 'import_file_dialog.dart';
import 'pin_dialog.dart';

class AuthenticateIntent extends Intent {
  const AuthenticateIntent();
}

class VerifyPinIntent extends Intent {
  const VerifyPinIntent();
}

class GenerateIntent extends Intent {
  const GenerateIntent();
}

class ImportIntent extends Intent {
  const ImportIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

Future<bool> _authenticate(
    WidgetRef ref, DevicePath devicePath, PivState pivState) async {
  final withContext = ref.read(withContextProvider);
  return await withContext((context) async =>
      await showBlurDialog(
        context: context,
        builder: (context) => AuthenticationDialog(
          devicePath,
          pivState,
        ),
      ) ??
      false);
}

Future<bool> _authIfNeeded(
    WidgetRef ref, DevicePath devicePath, PivState pivState) async {
  if (pivState.needsAuth) {
    return await _authenticate(ref, devicePath, pivState);
  }
  return true;
}

Widget registerPivActions(
  DevicePath devicePath,
  PivState pivState,
  PivSlot pivSlot, {
  required WidgetRef ref,
  required Widget Function(BuildContext context) builder,
  Map<Type, Action<Intent>> actions = const {},
}) =>
    Actions(
      actions: {
        AuthenticateIntent: CallbackAction<AuthenticateIntent>(
          onInvoke: (intent) => _authenticate(ref, devicePath, pivState),
        ),
        GenerateIntent:
            CallbackAction<GenerateIntent>(onInvoke: (intent) async {
          if (!pivState.protectedKey &&
              !await _authIfNeeded(ref, devicePath, pivState)) {
            return false;
          }

          final withContext = ref.read(withContextProvider);

          // TODO: Avoid asking for PIN if not needed?
          final verified = await withContext((context) async =>
                  await showBlurDialog(
                      context: context,
                      builder: (context) => PinDialog(devicePath))) ??
              false;

          if (!verified) {
            return false;
          }

          return await withContext((context) async {
            final l10n = AppLocalizations.of(context)!;
            final PivGenerateResult? result = await showBlurDialog(
              context: context,
              builder: (context) => GenerateKeyDialog(
                devicePath,
                pivState,
                pivSlot,
              ),
            );

            switch (result?.generateType) {
              case GenerateType.csr:
                final filePath = await FilePicker.platform.saveFile(
                  dialogTitle: l10n.l_export_csr_file,
                  allowedExtensions: ['csr'],
                  type: FileType.custom,
                  lockParentWindow: true,
                );
                if (filePath != null) {
                  final file = File(filePath);
                  await file.writeAsString(result!.result, flush: true);
                }
                break;
              default:
                break;
            }

            return result != null;
          });
        }),
        ImportIntent: CallbackAction<ImportIntent>(onInvoke: (intent) async {
          if (!await _authIfNeeded(ref, devicePath, pivState)) {
            return false;
          }

          final withContext = ref.read(withContextProvider);

          final picked = await withContext(
            (context) async {
              final l10n = AppLocalizations.of(context)!;
              return await FilePicker.platform.pickFiles(
                  allowedExtensions: ['pem', 'der', 'pfx', 'p12', 'key', 'crt'],
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
                  pivSlot,
                  File(picked.paths.first!),
                ),
              ) ??
              false);
        }),
        ExportIntent: CallbackAction<ExportIntent>(onInvoke: (intent) async {
          final (_, cert) = await ref
              .read(pivSlotsProvider(devicePath).notifier)
              .read(pivSlot.slot);

          if (cert == null) {
            return false;
          }

          final withContext = ref.read(withContextProvider);

          final filePath = await withContext((context) async {
            final l10n = AppLocalizations.of(context)!;
            return await FilePicker.platform.saveFile(
              dialogTitle: l10n.l_export_certificate_file,
              allowedExtensions: ['pem'],
              type: FileType.custom,
              lockParentWindow: true,
            );
          });

          if (filePath == null) {
            return false;
          }

          final file = File(filePath);
          await file.writeAsString(cert, flush: true);

          await withContext((context) async {
            final l10n = AppLocalizations.of(context)!;
            showMessage(context, l10n.l_certificate_exported);
          });
          return true;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          if (!await _authIfNeeded(ref, devicePath, pivState)) {
            return false;
          }
          final withContext = ref.read(withContextProvider);
          final bool? deleted = await withContext((context) async =>
              await showBlurDialog(
                context: context,
                builder: (context) => DeleteCertificateDialog(
                  devicePath,
                  pivSlot,
                ),
              ) ??
              false);

          // Needs to move to slot dialog(?) or react to state change
          // Pop the slot dialog if deleted
          if (deleted == true) {
            await withContext((context) async {
              Navigator.of(context).pop();
            });
          }
          return deleted;
        }),
        ...actions,
      },
      child: Builder(builder: builder),
    );

List<ActionItem> buildSlotActions(bool hasCert, AppLocalizations l10n) {
  return [
    ActionItem(
      key: keys.generateAction,
      icon: const Icon(Icons.add_outlined),
      actionStyle: ActionStyle.primary,
      title: l10n.s_generate_key,
      subtitle: l10n.l_generate_desc,
      intent: const GenerateIntent(),
    ),
    ActionItem(
      key: keys.importAction,
      icon: const Icon(Icons.file_download_outlined),
      title: l10n.l_import_file,
      subtitle: l10n.l_import_desc,
      intent: const ImportIntent(),
    ),
    if (hasCert) ...[
      ActionItem(
        key: keys.exportAction,
        icon: const Icon(Icons.file_upload_outlined),
        title: l10n.l_export_certificate,
        subtitle: l10n.l_export_certificate_desc,
        intent: const ExportIntent(),
      ),
      ActionItem(
        key: keys.deleteAction,
        actionStyle: ActionStyle.error,
        icon: const Icon(Icons.delete_outline),
        title: l10n.l_delete_certificate,
        subtitle: l10n.l_delete_certificate_desc,
        intent: const DeleteIntent(),
      ),
    ],
  ];
}
