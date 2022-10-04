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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/desktop/state.dart';

import 'rpc.dart';

class RpcQrScanner implements QrScanner {
  final RpcSession _rpc;
  RpcQrScanner(this._rpc);

  @override
  Future<String?> scanQr([String? imageData]) async {
    final result = await _rpc.command('qr', [], params: {'image': imageData});
    return result['result'];
  }
}

final desktopQrScannerProvider = Provider<QrScanner?>(
  (ref) => RpcQrScanner(ref.watch(rpcProvider)),
);
