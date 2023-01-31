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
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../../app/state.dart';
import '../../desktop/state.dart';
import 'rpc.dart';

final _log = Logger('helper');

class RpcQrScanner implements QrScanner {
  final RpcSession _rpc;
  RpcQrScanner(this._rpc);

  @override
  Future<String?> scanQr([String? imageData]) async {
    if (imageData == null) {
      _log.info('Get screenshot from rpc');
      final result = await _rpc.command('capture_screen', []);
      imageData = result['result'] as String;
    }

    final base64Image = imageData;
    try {
      return await Isolate.run(() async {
        var image = img.decodePng(base64Decode(base64Image))!;
        LuminanceSource source = RGBLuminanceSource(
            image.width,
            image.height,
            image
                .convert(numChannels: 4)
                .getBytes(order: img.ChannelOrder.abgr)
                .buffer
                .asInt32List());
        final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));

        final hints = DecodeHints();
        hints.put(DecodeHintType.possibleFormats, [BarcodeFormat.qrCode]);
        // ignore: void_checks
        hints.put(DecodeHintType.tryHarder, true);

        final reader = QRCodeReader();
        return reader.decode(bitmap, hints: hints).text;
      });
    } catch (e) {
      rethrow;
    }
  }
}

final desktopQrScannerProvider = Provider<QrScanner?>(
  (ref) {
    final rpc = ref.watch(rpcProvider).valueOrNull;
    return rpc != null ? RpcQrScanner(rpc) : null;
  },
);
