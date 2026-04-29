/*
 * Copyright (C) 2022-2026 Yubico.
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

import '../../generated/l10n/app_localizations.dart';
import '../../oath/models.dart';
import '../app_methods.dart';
import 'qr_scanner_overlay_view.dart'
    show QRScannerCutoutBackground, QRScannerBorder;
import 'qr_scanner_permissions_view.dart';
import 'qr_scanner_scan_status.dart';
import 'qr_scanner_widgets.dart';

/// Shows Camera preview, overlay and UI
/// Handles user interactions
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

GlobalKey<QRScannerZxingViewState> _zxingViewKey = GlobalKey();
const double _kMaxCutoutSize = 400;

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver {
  String? _scannedString;

  ScanStatus _status = ScanStatus.scanning;
  bool _previewInitialized = false;
  bool _permissionsGranted = false;
  bool _scanningReady = false;

  void setError() {
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
      _scannedString = null;
      _status = ScanStatus.scanning;

      _zxingViewKey.currentState?.resumeScanning();
    });
  }

  void handleResult(String qrCodeData) {
    if (_status != ScanStatus.scanning || !_scanningReady) {
      return;
    }
    setState(() {
      if (qrCodeData.isNotEmpty) {
        try {
          CredentialData.fromUri(Uri.parse(qrCodeData));
          _scannedString = qrCodeData;
          _status = ScanStatus.success;

          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (navigator.canPop()) {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _previewInitialized &&
        !_permissionsGranted) {
      _zxingViewKey.currentState?.recheckPermissions();
    }
  }

  Widget _buildTextContent(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.s_qr_scan,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.l_point_camera_scan,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCutout(ThemeData theme) {
    return Stack(
      children: [
        // Layer 1: Camera preview (full area, not clipped)
        Visibility(
          maintainState: true,
          maintainInteractivity: true,
          maintainAnimation: true,
          maintainSize: true,
          visible: _permissionsGranted,
          child: QRScannerZxingView(
            key: _zxingViewKey,
            overlaySizeFraction: 1.0,
            onDetect: (scannedData) => handleResult(scannedData),
            onViewInitialized: (bool permissionsGranted) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (!mounted) return;
                setState(() {
                  _previewInitialized = true;
                  _permissionsGranted = permissionsGranted;
                });
                // Delay scanning readiness to ignore any buffered frames
                // from a previous session.
                if (permissionsGranted) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() {
                        _scanningReady = true;
                      });
                    }
                  });
                }
              });
            },
            beforePermissionsRequest: () async {
              await preserveConnectedDeviceWhenPaused();
            },
          ),
        ),
        // Layer 2: Background with cutout hole (masks camera to rounded rect)
        QRScannerCutoutBackground(backgroundColor: theme.colorScheme.surface),
        // Layer 3: Rounded rect border around the cutout
        Visibility(
          visible: _permissionsGranted,
          child: QRScannerBorder(
            status: _status,
            primaryColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: isLandscape
                  ? _buildLandscapeLayout(l10n, theme)
                  : _buildPortraitLayout(l10n, theme),
            ),
          ),
          // Show permissions UI on top when needed
          Visibility(
            visible: _previewInitialized && !_permissionsGranted,
            child: QRScannerPermissionsUI(
              onPermissionRequest: () {
                _zxingViewKey.currentState?.requestPermissions();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const QrScannerTopBar(),
        const SizedBox(height: 24),
        _buildTextContent(l10n, theme),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxCutoutSize),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildScannerCutout(theme),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        const QrScannerNoQrCodeGroup(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout(AppLocalizations l10n, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const QrScannerTopBar(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildTextContent(l10n, theme),
              ),
              const Spacer(),
              const QrScannerNoQrCodeGroup(),
              const SizedBox(height: 18.0),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 45,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 24.0, 58.0, 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxCutoutSize),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildScannerCutout(theme),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
