/*
 * Copyright (C) 2022 Yubico.
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

import '../keys.dart' as keys;
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_util.dart';

class QRScannerUI extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;

  const QRScannerUI({
    super.key,
    required this.status,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scannerAreaWidth = getScannerAreaWidth(screenSize);

    return Stack(children: [
      /// instruction text under the scanner area
      Positioned.fromRect(
        rect: Rect.fromCenter(
            center: Offset(screenSize.width / 2,
                screenSize.height + scannerAreaWidth / 2.0 + 8.0),
            width: screenSize.width,
            height: screenSize.height),
        child: Text(
          status != ScanStatus.error
              ? l10n.l_point_camera_scan
              : l10n.l_invalid_qr,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),

      /// button for manual entry
      Positioned.fromRect(
        rect: Rect.fromCenter(
            center: Offset(screenSize.width / 2,
                screenSize.height + scannerAreaWidth / 2.0 + 80.0),
            width: screenSize.width,
            height: screenSize.height),
        child: Column(
          children: [
            Text(
              l10n.q_no_qr,
              textScaleFactor: 0.7,
              style: const TextStyle(color: Colors.white),
            ),
            OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop('');
                },
                key: keys.manualEntryButton,
                child: Text(
                  l10n.l_enter_manually,
                  style: const TextStyle(color: Colors.white),
                )),
          ],
        ),
      ),
    ]);
  }
}
