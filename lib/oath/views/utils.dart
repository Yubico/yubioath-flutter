/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../android/qr_scanner/qr_scanner_provider.dart';
import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../core/state.dart';
import '../../desktop/models.dart';
import '../../exception/cancellation_exception.dart';
import '../../widgets/utf8_utils.dart';
import '../keys.dart';
import '../models.dart';
import '../state.dart';
import 'add_account_page.dart';
import 'add_multi_account_page.dart';
import 'manage_password_dialog.dart';

/// Calculates the available space for issuer and account name.
///
/// Returns a record of the space available for the issuer and account name,
/// respectively, based on the current state of the credential.
(int, int) getRemainingKeySpace(
    {required OathType oathType,
    required int period,
    required String issuer,
    required String name}) {
  int remaining = 64; // The field is 64 bytes in total.

  if (oathType == OathType.totp && period != defaultPeriod) {
    // Non-standard TOTP periods are stored as part of this data, as a "D/"- prefix.
    remaining -= '$period/'.length;
  }
  int issuerSpace = byteLength(issuer);
  if (issuer.isNotEmpty) {
    // Issuer is separated from name with a ":", if present.
    issuerSpace += 1;
  }

  return (
    // Always reserve at least one character for name
    remaining - 1 - max(byteLength(name), 1),
    remaining - issuerSpace,
  );
}

/// Gets a textual name for the account, based on the issuer and name.
String getTextName(OathCredential credential) {
  return credential.issuer != null
      ? '${credential.issuer} (${credential.name})'
      : credential.name;
}

Future<void> handleUri(
  BuildContext context,
  List<OathCredential>? credentials,
  String qrData,
  DevicePath? devicePath,
  OathState? state,
  AppLocalizations l10n,
) async {
  List<CredentialData> creds;
  try {
    creds = CredentialData.fromUri(Uri.parse(qrData));
  } catch (_) {
    showMessage(context, l10n.l_invalid_qr);
    return;
  }
  if (creds.isEmpty) {
    showMessage(context, l10n.l_qr_not_found);
  } else if (creds.length == 1) {
    await showBlurDialog(
      context: context,
      builder: (context) => OathAddAccountPage(
        devicePath,
        state,
        credentials: credentials,
        credentialData: creds[0],
      ),
    );
  } else {
    await showBlurDialog(
      context: context,
      builder: (context) => OathAddMultiAccountPage(devicePath, state, creds,
          key: migrateAccountAction),
    );
  }
}

const maxQrFileSize = 5 * 1024 * 1024;

Future<String?> handleQrFile(File file, BuildContext context,
    WithContext withContext, QrScanner qrScanner) async {
  final l10n = AppLocalizations.of(context)!;
  if (await file.length() > maxQrFileSize) {
    await withContext((context) async {
      showMessage(
          context,
          l10n.l_qr_not_read(
              l10n.l_qr_file_too_large('${maxQrFileSize / (1024 * 1024)} MB')));
    });
    return null;
  }

  final fileData = await file.readAsBytes();
  final b64Image = base64Encode(fileData);

  try {
    final qrData = await qrScanner.scanQr(b64Image);
    if (qrData == null) {
      await withContext((context) async {
        showMessage(context, l10n.l_qr_not_found);
      });
      return null;
    }
    return qrData;
  } catch (e) {
    final String errorMessage;
    if (e is RpcError) {
      if (e.status == 'invalid-image') {
        errorMessage = l10n.l_qr_invalid_image_file;
      } else {
        errorMessage = e.message;
      }
    } else {
      errorMessage = e.toString();
    }
    await withContext((context) async {
      showMessage(context, l10n.l_qr_not_read(errorMessage));
    });
    return null;
  }
}

Future<void> addOathAccount(BuildContext context, WidgetRef ref,
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
    final credentials = ref.read(credentialsProvider);
    await showBlurDialog(
      context: context,
      builder: (context) =>
          OathAddAccountPage(devicePath, oathState, credentials: credentials),
    );
  }
}

Future<void> managePassword(BuildContext context, WidgetRef ref,
    DevicePath devicePath, OathState oathState) async {
  await showBlurDialog(
    context: context,
    builder: (context) => ManagePasswordDialog(devicePath, oathState),
  );
}
