/*
 * Copyright (C) 2022-2026 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../generated/l10n/app_localizations.dart';
import '../keys.dart' as keys;
import 'qr_scanner_provider.dart';

/// Top bar with back button (left) and QR icon (centered).
class QrScannerTopBar extends StatelessWidget {
  const QrScannerTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Icon(
          Symbols.qr_code_2_add,
          color: theme.colorScheme.secondary,
          size: 40,
          weight: 900,
        ),
      ],
    );
  }
}

/// "No QR code?" text with "Enter manually" and "Read from file" buttons.
class QrScannerNoQrCodeGroup extends StatelessWidget {
  const QrScannerNoQrCodeGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.q_no_qr, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(AndroidQrScanner.kQrScannerRequestManualEntry);
              },
              key: keys.manualEntryButton,
              child: Text(l10n.s_enter_manually),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(AndroidQrScanner.kQrScannerRequestReadFromFile);
              },
              key: keys.readFromImage,
              child: Text(l10n.s_read_from_file),
            ),
          ],
        ),
      ],
    );
  }
}
