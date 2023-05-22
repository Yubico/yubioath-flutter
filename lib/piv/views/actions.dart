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
import 'package:yubico_authenticator/app/models.dart';

import '../../app/message.dart';
import '../../app/shortcuts.dart';
import '../../app/state.dart';
import '../models.dart';
import '../state.dart';
import 'authentication_dialog.dart';
import 'delete_certificate_dialog.dart';

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

Future<PivImportResult> _importFile(
    WidgetRef ref, DevicePath devicePath, PivSlot pivSlot) async {
  final picked = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pem', 'der', 'pfx', 'p12', 'key', 'crt'],
      type: FileType.custom,
      allowMultiple: false,
      lockParentWindow: true,
      dialogTitle: 'Select file to import');
  if (picked != null && picked.files.isNotEmpty) {
    final filePath = picked.paths.first!;
    final file = File(filePath);
    final data = await file.readAsBytes();
    final hexData = data.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

    return await ref
        .read(pivSlotsProvider(devicePath).notifier)
        .import(pivSlot.slot, hexData);
  }
  return PivImportResult(metadata: null, publicKey: null, certificate: null);
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
        ImportIntent: CallbackAction<ImportIntent>(onInvoke: (intent) async {
          if (!pivState.authenticated) {
            await _authenticate(ref, devicePath, pivState);
          }
          final result = await _importFile(ref, devicePath, pivSlot);
          await ref.read(withContextProvider)((context) async {
            if (result.publicKey != null && result.certificate != null) {
              showMessage(context, 'Private key and certificate imported');
            } else if (result.publicKey != null) {
              showMessage(context, 'Private key imported');
            } else if (result.certificate != null) {
              showMessage(context, 'Certificate imported');
            } else {
              return false;
            }
            return true;
          });
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) async {
          if (!pivState.authenticated) {
            await _authenticate(ref, devicePath, pivState);
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
        }), //TODO
        ...actions,
      },
      child: Builder(builder: builder),
    );
