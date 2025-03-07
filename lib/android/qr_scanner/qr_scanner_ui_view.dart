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
import '../keys.dart' as keys;
import 'qr_scanner_provider.dart';
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_widgets.dart';

class QRScannerUI extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;
  final GlobalKey overlayWidgetKey;

  const QRScannerUI(
      {super.key,
      required this.status,
      required this.screenSize,
      required this.overlayWidgetKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 0, bottom: 0),
                  child: SizedBox(
                    // other widgets can find the RenderObject of this
                    // widget by its key value and query its size and offset.
                    key: overlayWidgetKey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Text(
                  status != ScanStatus.error
                      ? l10n.l_point_camera_scan
                      : l10n.l_invalid_qr,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SmallWhiteText(l10n.q_no_qr),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                              AndroidQrScanner.kQrScannerRequestManualEntry);
                        },
                        key: keys.manualEntryButton,
                        child: Text(
                          l10n.s_enter_manually,
                          style: const TextStyle(color: Colors.white),
                        )),
                    const SizedBox(width: 16),
                    OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                              AndroidQrScanner.kQrScannerRequestReadFromFile);
                        },
                        key: keys.readFromImage,
                        child: Text(
                          l10n.s_read_from_file,
                          style: const TextStyle(color: Colors.white),
                        ))
                  ])
                ],
              ),
              const SizedBox(height: 16)
            ],
          ),
        )
      ],
    );
  }
}
