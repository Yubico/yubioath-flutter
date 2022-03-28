import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/app/state.dart';

import '../../app/navigation_service.dart';
import 'qr_scanner_view.dart';

class AndroidQrScanner implements QrScanner {
  AndroidQrScanner();

  @override
  Future<String> scanQr() async {
    var code =
        await Navigator.of(NavigationService.navigatorKey.currentContext!)
            .push(MaterialPageRoute(
      builder: (context) => const QrScannerView(),
    ));

    return code;
  }
}

final androidQrScannerProvider = Provider<QrScanner?>(
  (ref) => AndroidQrScanner(),
);
