import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/navigation_service.dart';

class QrScannerView extends StatelessWidget {
  const QrScannerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(0),
      child: Stack(children: [
        MobileScanner(
            controller: MobileScannerController(
                facing: CameraFacing.back, torchEnabled: false),
            onDetect: (barcode, args) {
              final String? code = barcode.rawValue;
              BuildContext dialogContext =
                  NavigationService.navigatorKey.currentContext!;
              if (Navigator.of(dialogContext).canPop()) {
                // prevent several callbacks
                Navigator.of(dialogContext).pop(code);
              }
            }),
      ]),
    ));
  }
}
