/*
 * Copyright (C) 2024 Yubico.
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

import '../android/qr_scanner/qr_scanner_provider.dart';
import '../app/message.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../core/state.dart';
import '../exception/cancellation_exception.dart';
import 'models.dart';
import 'views/add_account_dialog.dart';

void addOathAccount(BuildContext context, WidgetRef ref,
    [DevicePath? devicePath, OathState? oathState]) async {
  if (isAndroid) {
    final l10n = AppLocalizations.of(context)!;
    final withContext = ref.read(withContextProvider);
    final qrScanner = ref.read(qrScannerProvider);
    if (qrScanner != null) {
      try {
        final qrData = await qrScanner.scanQr();
        await AndroidQrScanner.handleScannedData(
            qrData, withContext, qrScanner, l10n);
      } on CancellationException catch (_) {
        //ignored - user cancelled
        return;
      }
    } else {
      // no QR scanner - enter data manually
      await AndroidQrScanner.showAccountManualEntryDialog(withContext, l10n);
    }
  } else {
    await showBlurDialog(
      context: context,
      builder: (context) => AddAccountDialog(devicePath, oathState),
    );
  }
}
