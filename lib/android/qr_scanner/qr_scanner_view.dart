import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/navigation_service.dart';
import '../../oath/models.dart';

class MobileScannerWrapper extends StatefulWidget {
  final MobileScannerController controller;
  final Function(Barcode barcode, MobileScannerArguments? args)? onDetect;
  final double dimension;
  final Color frameColor;
  const MobileScannerWrapper({
    Key? key,
    required this.controller,
    required this.dimension,
    required this.frameColor,
    this.onDetect,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MobileScannerWrapperState();
}

class _MobileScannerWrapperState extends State<MobileScannerWrapper> {
  @override
  Widget build(BuildContext context) {
    const radius = 40.0;
    return Stack(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox.square(
              dimension: widget.dimension,
              child: MobileScanner(
                  controller: widget.controller,
                  onDetect: (barcode, args) {
                    widget.onDetect?.call(barcode, args);
                  }))),
      DecoratedBox(
          child: SizedBox(
            width: widget.dimension,
            height: widget.dimension,
          ),
          decoration: BoxDecoration(
              border: Border.all(color: widget.frameColor, width: 5),
              borderRadius: const BorderRadius.all(Radius.circular(radius))))
    ]);
  }
}

class QrScannerView extends StatefulWidget {
  const QrScannerView({Key? key}) : super(key: key);

  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  String? _scannedString;
  CredentialData? _credentialData;
  String? _scanningError;
  Color _frameColor = Colors.grey;
  final MobileScannerController _controller =
      MobileScannerController(facing: CameraFacing.back, torchEnabled: false);

  void handleResult(String? code) {
    setState(() {
      if (code != null) {
        try {
          var parsedCredential = CredentialData.fromUri(Uri.parse(code));
          _frameColor = Colors.green;
          _credentialData = parsedCredential;
          _scanningError = null;
          _scannedString = code;
        } on ArgumentError catch (_) {
          _frameColor = Colors.red;
          _credentialData = null;
          _scanningError = 'Invalid code';
          _scannedString = null;
        }
      } else {
        _frameColor = Colors.red;
        _credentialData = null;
        _scanningError = 'Invalid code';
        _scannedString = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BuildContext dialogContext = NavigationService.navigatorKey.currentContext!;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Scan QR code'),
              //actions: actions,
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MobileScannerWrapper(
                          controller: _controller,
                          dimension: MediaQuery.of(context).size.width - 64,
                          frameColor: _frameColor,
                          onDetect: (barcode, _) =>
                              handleResult(barcode.rawValue),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    if (_credentialData == null && _scanningError == null)
                      Card(
                          elevation: 10,
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                // mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Scan QR code',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  const SizedBox(height: 16),
                                  Text('or',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop('');
                                        },
                                        child: const Text('Add manually'),
                                      ),
                                    ],
                                  )
                                ],
                              ))),
                    if (_credentialData != null)
                      Card(
                          elevation: 10,
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Successfully scanned',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text('Name',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  Text(_credentialData?.name ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline6),
                                  if (_credentialData?.issuer != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 16,
                                        ),
                                        Text('Issuer',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text(_credentialData?.issuer ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline6),
                                        const SizedBox(
                                          height: 32,
                                        ),
                                      ],
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (Navigator.of(dialogContext)
                                              .canPop()) {
                                            // prevent several callbacks
                                            Navigator.of(dialogContext)
                                                .pop(_scannedString);
                                          }
                                        },
                                        child: const Text('Add this'),
                                      )
                                    ],
                                  )
                                ],
                              ))),
                    if (_scanningError != null)
                      Card(
                          elevation: 10,
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Scan failed, try again',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  const SizedBox(height: 16),
                                  Text('or',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop('');
                                        },
                                        child: const Text('Add manually'),
                                      ),
                                    ],
                                  )
                                ],
                              ))),
                  ],
                ))));
  }
}
