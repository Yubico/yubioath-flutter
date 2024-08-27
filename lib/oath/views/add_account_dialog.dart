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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/file_drop_overlay.dart';
import '../../widgets/file_drop_target.dart';
import '../../widgets/responsive_dialog.dart';
import '../keys.dart';
import '../models.dart';
import '../state.dart';
import 'add_account_page.dart';
import 'utils.dart';

class AddAccountDialog extends ConsumerStatefulWidget {
  final DevicePath? devicePath;
  final OathState? state;

  const AddAccountDialog(this.devicePath, this.state, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final credentials = ref.read(credentialsProvider);
    final withContext = ref.read(withContextProvider);

    final qrScanner = ref.watch(qrScannerProvider);
    return FileDropTarget(
      onFileDropped: (file) async {
        Navigator.of(context).pop();
        if (qrScanner != null) {
          final qrData =
              await handleQrFile(file, context, withContext, qrScanner);
          if (qrData != null) {
            await withContext((context) async {
              await handleUri(context, credentials, qrData, widget.devicePath,
                  widget.state, l10n);
            });
          }
        }
      },
      overlay: FileDropOverlay(
        title: l10n.s_add_account,
        subtitle: l10n.l_drop_qr_description,
      ),
      child: ResponsiveDialog(
        title: Text(l10n.s_add_account),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.p_add_description),
              const SizedBox(height: 4),
              Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.0,
                  runSpacing: 8.0,
                  children: [
                    ActionChip(
                      avatar: const Icon(Symbols.qr_code_scanner),
                      label: Text(l10n.s_qr_scan),
                      onPressed: () async {
                        if (qrScanner != null) {
                          final qrData = await qrScanner.scanQr();
                          await withContext(
                            (context) async {
                              if (qrData != null) {
                                Navigator.of(context).pop();
                                await handleUri(context, credentials, qrData,
                                    widget.devicePath, widget.state, l10n);
                              } else {
                                showMessage(context, l10n.l_qr_not_found);
                              }
                            },
                          );
                        }
                      },
                    ),
                    ActionChip(
                        key: addAccountManuallyButton,
                        avatar: const Icon(Symbols.edit),
                        label: Text(l10n.s_add_manually),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await withContext((context) async {
                            await showBlurDialog(
                              context: context,
                              builder: (context) => OathAddAccountPage(
                                widget.devicePath,
                                widget.state,
                                credentials: credentials,
                              ),
                            );
                          });
                        }),
                  ])
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
