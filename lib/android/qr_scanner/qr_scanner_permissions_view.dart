/*
 * Copyright (C) 2022-2025 Yubico.
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

import '../../generated/l10n/app_localizations.dart';
import 'qr_scanner_provider.dart';
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_widgets.dart';

class QRScannerPermissionsUI extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;
  final Function onPermissionRequest;

  const QRScannerPermissionsUI({
    super.key,
    required this.status,
    required this.screenSize,
    required this.onPermissionRequest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              l10n.p_need_camera_permission,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        SmallWhiteText(l10n.q_want_to_scan),
                        OutlinedButton(
                          onPressed: () {
                            onPermissionRequest();
                          },
                          child: Text(
                            l10n.s_review_permissions,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [SmallWhiteText(l10n.q_have_account_info)],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(AndroidQrScanner.kQrScannerRequestManualEntry);
                      },
                      child: Text(
                        l10n.s_enter_manually,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(AndroidQrScanner.kQrScannerRequestReadFromFile);
                      },
                      child: Text(
                        l10n.s_read_from_file,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
