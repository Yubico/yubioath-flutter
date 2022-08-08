import 'package:flutter/material.dart';

import 'qr_scanner_scan_status.dart';
import 'qr_scanner_util.dart';

class QRScannerPermissionsUI extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;
  final Function onPermissionRequest;

  const QRScannerPermissionsUI({
    super.key,
    required this.status,
    required this.screenSize,
    required this.onPermissionRequest
  });

  @override
  Widget build(BuildContext context) {
    var scannerAreaWidth = getScannerAreaWidth(screenSize);

    return Stack(children: [
      /// instruction text under the scanner area
      Positioned.fromRect(
          rect: Rect.fromCenter(
              center: Offset(screenSize.width / 2,
                  screenSize.height - scannerAreaWidth / 2.0 + 8.0),
              width: screenSize.width,
              height: screenSize.height),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Yubico Authenticator needs Camera permissions for scanning QR codes.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )),

      /// button for manual entry
      Positioned.fromRect(
        rect: Rect.fromCenter(
            center: Offset(screenSize.width / 2, screenSize.height),
            width: screenSize.width,
            height: screenSize.height),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
          Column(
            children: [
              const Text(
                'Have account info?',
                textScaleFactor: 0.7,
                style: TextStyle(color: Colors.white),
              ),
              OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Enter manually',
                      style: TextStyle(color: Colors.white))),
            ],
          ),
              Column(
                children: [
                  const Text(
                    'Would like to scan?',
                    textScaleFactor: 0.7,
                    style: TextStyle(color: Colors.white),
                  ),
                  OutlinedButton(
                      onPressed: () {
                        onPermissionRequest();
                      },
                      child: const Text('Review permissions',
                          style: TextStyle(color: Colors.white))),
                ],
              )
        ]),
      ),
    ]);
  }
}
