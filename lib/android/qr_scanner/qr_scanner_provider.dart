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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/exception/cancellation_exception.dart';
import 'package:yubico_authenticator/theme.dart';

import 'package:qrscanner_zxing/qrscanner_zxing_method_channel.dart';

import 'qr_scanner_view.dart';

class AndroidQrScanner implements QrScanner {
  final WithContext _withContext;

  AndroidQrScanner(this._withContext);

  @override
  Future<String?> scanQr([String? imageData]) async {
    if (imageData == null) {
      var scannedCode = await _withContext(
              (context) async =>
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
}

QrScanner? Function(dynamic) androidQrScannerProvider(hasCamera) {
  return (ref) =>
  hasCamera ? AndroidQrScanner(ref.watch(withContextProvider)) : null;
}
