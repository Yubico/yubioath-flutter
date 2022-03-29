import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/navigation_service.dart';
import '../../oath/models.dart';

class OverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 40.0;
    var w = size.width - 40;
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectXY(
          Rect.fromPoints(
              const Offset(32, 32), Offset(size.width - 32, 32 + w)),
          r,
          r))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class MobileScannerWrapper extends StatelessWidget {
  final MobileScannerController controller;
  final Function(Barcode barcode, MobileScannerArguments? args)? onDetect;
  final Color frameColor;

  const MobileScannerWrapper({
    Key? key,
    required this.controller,
    required this.frameColor,
    required this.onDetect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const radius = 40.0;
    var dimension = MediaQuery.of(context).size.width - 64;
    return Stack(children: [
      MobileScanner(
          controller: controller,
          onDetect: (barcode, args) {
            onDetect?.call(barcode, args);
          }),
      ClipPath(
          clipper: OverlayClipper(),
          child: Opacity(
              opacity: 0.5,
              child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [Spacer()],
                  )))),
      Positioned.fromRect(
          rect: Rect.fromPoints(
              const Offset(32, 32), Offset(dimension + 32, 60 + dimension)),
          child: DecoratedBox(
              child: SizedBox(
                width: dimension,
                height: dimension,
              ),
              decoration: BoxDecoration(
                  border: Border.all(color: frameColor, width: 5),
                  borderRadius:
                      const BorderRadius.all(Radius.circular(radius)))))
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
            body: Stack(children: [
              MobileScannerWrapper(
                controller: _controller,
                frameColor: _frameColor,
                onDetect: (barcode, _) => handleResult(barcode.rawValue),
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                  )),
            ])));
  }
}
