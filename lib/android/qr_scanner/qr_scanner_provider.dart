import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';

import 'qr_scanner_view.dart';

class AndroidQrScanner implements QrScanner {
  final WithContext _withContext;
  AndroidQrScanner(this._withContext);

  @override
  Future<String> scanQr([String? _]) async => _withContext((context) async {
        return await Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const QrScannerView(),
          transitionDuration: const Duration(seconds: 0),
          reverseTransitionDuration: const Duration(seconds: 0),
        )) ?? '';
      });
}

final androidQrScannerProvider = Provider<QrScanner?>(
  (ref) => AndroidQrScanner(ref.watch(withContextProvider)),
);
