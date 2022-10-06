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

import 'package:flutter/material.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_view.dart';

import '../../oath/models.dart';
import 'qr_scanner_overlay_view.dart';
import 'qr_scanner_permissions_view.dart';
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_ui_view.dart';

/// Shows Camera preview, overlay and UI
/// Handles user interactions
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

GlobalKey<QRScannerZxingViewState> _zxingViewKey = GlobalKey();

class _QrScannerViewState extends State<QrScannerView> {
  String? _scannedString;

  // will be used later
  // ignore: unused_field
  CredentialData? _credentialData;
  ScanStatus _status = ScanStatus.scanning;
  bool _previewInitialized = false;
  bool _permissionsGranted = false;

  void setError() {
    _credentialData = null;
    _scannedString = null;
    _status = ScanStatus.error;

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        resetError();
      }
    });
  }

  void resetError() {
    setState(() {
      _credentialData = null;
      _scannedString = null;
      _status = ScanStatus.scanning;

      _zxingViewKey.currentState?.resumeScanning();

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
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
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
          Container(
              color: Colors.black,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [Spacer()])),
          Visibility(
              maintainState: true,
              maintainInteractivity: true,
              maintainAnimation: true,
              maintainSize: true,
              visible: _permissionsGranted,
              child: QRScannerZxingView(
                  key: _zxingViewKey,
                  marginPct: 50,
                  onDetect: (scannedData) => handleResult(scannedData),
                  onViewInitialized: (bool permissionsGranted) {
                    Future.delayed(const Duration(milliseconds: 50), () {
                      setState(() {
                        _previewInitialized = true;
                        _permissionsGranted = permissionsGranted;
                      });
                    });
                  })),
          Visibility(
              visible: _permissionsGranted,
              child: QRScannerOverlay(
                status: _status,
                screenSize: screenSize,
              )),
          Visibility(
              visible: _permissionsGranted,
              child: QRScannerUI(
                status: _status,
                screenSize: screenSize,
              )),
          Visibility(
              visible: _previewInitialized && !_permissionsGranted,
              child: QRScannerPermissionsUI(
                status: _status,
                screenSize: screenSize,
                onPermissionRequest: () {
                  _zxingViewKey.currentState?.requestPermissions();
                },
              )),
        ],
      ),
    );
  }
}
