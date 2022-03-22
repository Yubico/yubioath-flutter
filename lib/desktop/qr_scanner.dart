import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/desktop/state.dart';

import 'rpc.dart';

class RpcQrScanner implements QrScanner {
  final RpcSession _rpc;
  RpcQrScanner(this._rpc);

  @override
  Future<String> scanQr(String? filePath) async {
    if (filePath != null) {
      final result = await _rpc.command('qr', [], params: {'image': filePath});
      return result['result'];
    } else {
      final result = await _rpc.command('qr', []);
      return result['result'];
    }
  }
}

final desktopQrScannerProvider = Provider<QrScanner?>(
  (ref) => RpcQrScanner(ref.watch(rpcProvider)),
);
