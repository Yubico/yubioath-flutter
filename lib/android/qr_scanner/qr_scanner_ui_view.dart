import 'package:flutter/material.dart';

import '../keys.dart' as keys;
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_util.dart';

class QRScannerUI extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;

  const QRScannerUI({
    super.key,
    required this.status,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    var scannerAreaWidth = getScannerAreaWidth(screenSize);

    return Stack(children: [
      /// instruction text under the scanner area
      Positioned.fromRect(
        rect: Rect.fromCenter(
            center: Offset(screenSize.width / 2,
                screenSize.height + scannerAreaWidth / 2.0 + 8.0),
            width: screenSize.width,
            height: screenSize.height),
        child: Text(
          status != ScanStatus.error
              ? 'Point your camera at a QR code to scan it'
              : 'Invalid QR code',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),

      /// button for manual entry
      Positioned.fromRect(
        rect: Rect.fromCenter(
            center: Offset(screenSize.width / 2,
                screenSize.height + scannerAreaWidth / 2.0 + 80.0),
            width: screenSize.width,
            height: screenSize.height),
        child: Column(
          children: [
            const Text(
              'No QR code?',
              textScaleFactor: 0.7,
              style: TextStyle(color: Colors.white),
            ),
            OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop('');
                },
                key: keys.manualEntryButton,
                child: const Text('Enter manually',
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    ]);
  }
}
