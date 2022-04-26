import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';

import '../../app/navigation_service.dart';
import 'qr_scanner_view.dart';

class AndroidQrScanner implements QrScanner {
  AndroidQrScanner();

  @override
  Future<String> scanQr([String? _]) async {
    var code =
        await Navigator.of(NavigationService.navigatorKey.currentContext!)
            .push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const QrScannerView(),
      transitionDuration: const Duration(seconds: 0),
      reverseTransitionDuration: const Duration(seconds: 0),
    ));

    return code;
  }
}

final androidQrScannerProvider = Provider<QrScanner?>(
  (ref) => AndroidQrScanner(),
);
