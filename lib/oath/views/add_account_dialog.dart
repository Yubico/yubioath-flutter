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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/message.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/widgets/responsive_dialog.dart';

import '../../app/models.dart';
import '../../widgets/file_drop_target.dart';
import '../keys.dart';
import '../models.dart';
import '../state.dart';
import 'add_account_page.dart';
import 'add_multi_account_page.dart';

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
    return ResponsiveDialog(
        title: Text(l10n.s_add_account),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: FileDropTarget(
            onFileDropped: (fileData) async {
              Navigator.of(context).pop();
              if (qrScanner != null) {
                final b64Image = base64Encode(fileData);
                final uri = await qrScanner.scanQr(b64Image);
                if (uri == null) {
                  if (!mounted) return;
                  showMessage(context, l10n.l_qr_not_found);
                } else {
                  final otpauth = CredentialData.fromOtpauth(Uri.parse(uri));
                  await withContext((context) async {
                    await showBlurDialog(
                      context: context,
                      builder: (context) => OathAddAccountPage(
                        widget.devicePath,
                        widget.state,
                        credentials: credentials,
                        credentialData: otpauth,
                      ),
                    );
                  });
                }
              }
            },
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
                        avatar: const Icon(Icons.qr_code_scanner_outlined),
                        label: Text(l10n.s_qr_scan),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          if (qrScanner != null) {
                            final uri = await qrScanner.scanQr();
                            List<CredentialData> creds = uri != null
                                ? CredentialData.fromUri(Uri.parse(uri))
                                : [];
                            await withContext((context) async {
                              if (creds.isEmpty) {
                                showMessage(context, l10n.l_qr_not_found);
                              } else if (creds.length == 1) {
                                await showBlurDialog(
                                  context: context,
                                  builder: (context) => OathAddAccountPage(
                                    widget.devicePath,
                                    widget.state,
                                    credentials: credentials,
                                    credentialData: creds[0],
                                  ),
                                );
                              } else {
                                await showBlurDialog(
                                  context: context,
                                  builder: (context) => OathAddMultiAccountPage(
                                      widget.devicePath, widget.state, creds,
                                      key: migrateAccountAction),
                                );
                              }
                            });
                          }
                        },
                      ),
                      ActionChip(
                          avatar: const Icon(Icons.edit_outlined),
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
        ));
  }
}
