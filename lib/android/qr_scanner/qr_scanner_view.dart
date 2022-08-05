import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_view.dart';

import '../../oath/models.dart';
import 'qr_scanner_overlay_view.dart';
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_ui_view.dart';

/// Shows Camera preview, overlay and UI
/// Handles user interactions
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  String? _scannedString;

  // will be used later
  // ignore: unused_field
  CredentialData? _credentialData;
  ScanStatus _status = ScanStatus.scanning;

  void setError() {
    _credentialData = null;
    _scannedString = null;
    _status = ScanStatus.error;

    Future.delayed(const Duration(milliseconds: 2000), () {
      resetError();
    });
  }

  void resetError() {
    setState(() {
      _credentialData = null;
      _scannedString = null;
      _status = ScanStatus.scanning;
    });
  }

  void handleResult(String barCode) {
    if (_status != ScanStatus.scanning) {
      // on success and error ignore reported codes
      return;
    }
    setState(() {
      if (barCode.isNotEmpty) {
        try {
          var parsedCredential = CredentialData.fromUri(Uri.parse(barCode));
          _credentialData = parsedCredential;
          _scannedString = barCode;
          _status = ScanStatus.success;

          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (navigator.canPop()) {
              // prevent several callbacks
              navigator.pop(_scannedString);
            }
          });
        } on ArgumentError catch (_) {
          setError();
        } catch (e) {
          setError();
        }
      } else {
        setError();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _status = ScanStatus.scanning;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Add account',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          QRScannerZxingView(
              marginPct: 50,
              onDetect: (scannedData) => handleResult(scannedData)),
          QRScannerOverlay(
            status: _status,
            screenSize: MediaQuery.of(context).size,
          ),
          QRScannerUI(
            status: _status,
            screenSize: MediaQuery.of(context).size,
          )
        ],
      ),
    ));
  }
}
