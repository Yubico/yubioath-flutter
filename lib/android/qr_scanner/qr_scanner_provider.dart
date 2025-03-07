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

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';

import '../../app/message.dart';
import '../../app/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../oath/views/add_account_page.dart';
import '../../oath/views/utils.dart';
import '../../theme.dart';
import '../app_methods.dart';
import 'qr_scanner_view.dart';

class AndroidQrScanner implements QrScanner {
  static const String kQrScannerRequestManualEntry =
      '__QR_SCANNER_ENTER_MANUALLY__';
  static const String kQrScannerRequestReadFromFile =
      '__QR_SCANNER_SCAN_FROM_FILE__';
  final WithContext _withContext;

  AndroidQrScanner(this._withContext);

  @override
  Future<String?> scanQr([String? imageData]) async {
    if (imageData == null) {
      var scannedCode = await _withContext(
          (context) async => await Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, __, ___) => Theme(
                    data: AppTheme.getDarkTheme(defaultPrimaryColor),
                    child: const QrScannerView()),
                settings: const RouteSettings(name: 'android_qr_scanner_view'),
                transitionDuration: const Duration(seconds: 0),
                reverseTransitionDuration: const Duration(seconds: 0),
              )));
      if (scannedCode == null) {
        // user has cancelled the scan
        throw CancellationException();
      }
      if (scannedCode == '') {
        return null;
      }
      return scannedCode;
    } else {
      var zxingChannel = MethodChannelQRScannerZxing();
      return await zxingChannel.scanBitmap(base64Decode(imageData));
    }
  }

  static Future<void> showAccountManualEntryDialog(
      WithContext withContext, AppLocalizations l10n) async {
    await withContext((context) => showBlurDialog(
          context: context,
          routeSettings: const RouteSettings(name: 'oath_add_account'),
          builder: (context) {
            return const OathAddAccountPage(
              null,
              null,
              credentials: null,
            );
          },
        ));
  }

  static Future<void> readQrFromFile(WithContext withContext,
      QrScanner qrScanner, AppLocalizations l10n) async {
    await preserveConnectedDeviceWhenPaused();
    final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['png', 'jpg', 'gif', 'webp'],
        type: FileType.custom,
        allowMultiple: false,
        lockParentWindow: true,
        withData: true,
        dialogTitle: l10n.l_qr_select_file);

    if (result == null || !result.isSinglePick) {
      // no result
      return;
    }

    final bytes = result.files.first.bytes;
    if (bytes != null) {
      final b64bytes = base64Encode(bytes);
      final imageQrData = await qrScanner.scanQr(b64bytes);
      if (imageQrData != null) {
        await withContext((context) =>
            handleUri(context, null, imageQrData, null, null, l10n));
        return;
      }
    }
    // no QR code found
    await withContext(
        (context) async => showMessage(context, l10n.l_qr_not_found));
  }

  static Future<void> handleScannedData(
    String? qrData,
    WithContext withContext,
    QrScanner qrScanner,
    AppLocalizations l10n,
  ) async {
    switch (qrData) {
      case null:
        break;
      case kQrScannerRequestManualEntry:
        await showAccountManualEntryDialog(withContext, l10n);
      case kQrScannerRequestReadFromFile:
        await readQrFromFile(withContext, qrScanner, l10n);
      default:
        await withContext(
            (context) => handleUri(context, null, qrData, null, null, l10n));
    }
  }
}

QrScanner? Function(dynamic) androidQrScannerProvider(hasCamera) {
  return (ref) =>
      hasCamera ? AndroidQrScanner(ref.watch(withContextProvider)) : null;
}
