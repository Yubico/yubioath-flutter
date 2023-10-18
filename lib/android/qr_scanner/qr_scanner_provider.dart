/*
 * Copyright (C) 2022-2023 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/exception/cancellation_exception.dart';
import 'package:yubico_authenticator/theme.dart';

import '../../app/message.dart';
import '../../oath/views/add_account_page.dart';
import '../../oath/views/utils.dart';
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
      var scannedCode = await _withContext((context) async =>
          await Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                Theme(data: AppTheme.darkTheme, child: const QrScannerView()),
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

  static Future<void> handleScannedData(
      String? qrData, WidgetRef ref, AppLocalizations l10n) async {
    final withContext = ref.read(withContextProvider);
    switch (qrData) {
      case null:
        break;
      case kQrScannerRequestManualEntry:
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
      case kQrScannerRequestReadFromFile:
        final result = await FilePicker.platform.pickFiles(
            allowedExtensions: ['png', 'jpg', 'gif', 'webp'],
            type: FileType.custom,
            allowMultiple: false,
            lockParentWindow: true,
            withData: true,
            dialogTitle: 'Select file with QR code');

        if (result == null || !result.isSinglePick) {
          // no result
          return;
        }

        final bytes = result.files.first.bytes;
        final scanner = ref.read(qrScannerProvider);
        if (bytes != null && scanner != null) {
          final b64bytes = base64Encode(bytes);
          final qrData = await scanner.scanQr(b64bytes);
          if (qrData != null) {
            await withContext((context) =>
                handleUri(context, null, qrData, null, null, l10n));
            return;
          }
        }
        // no QR code found
        await withContext(
            (context) async => showMessage(context, l10n.l_qr_not_found));

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
