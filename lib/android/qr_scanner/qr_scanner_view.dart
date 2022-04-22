import 'package:flutter/material.dart';
import 'package:qrscanner_zxing/qrscanner_zxing_view.dart';

import '../../app/navigation_service.dart';
import '../../oath/models.dart';

/// Status of view state
enum _ScanStatus { looking, error, success }

class OverlayClipper extends CustomClipper<Path> {
  /// helper method to calculate position of the rect
  Rect _getOverlayRect(Size size, double width) => Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: width);

  @override
  Path getClip(Size size) {
    const r = 40.0;
    var w = size.width - 40;
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectXY(_getOverlayRect(size, w), r, r))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class MobileScannerWrapper extends StatelessWidget {
  final Function(ScannedData) onDetect;
  final _ScanStatus status;

  const MobileScannerWrapper({
    Key? key,
    required this.onDetect,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var backgroundColor = status == _ScanStatus.looking
        ? Colors.white
        : status == _ScanStatus.error
            ? Colors.red.shade900
            : Colors.green.shade900;

    var size = MediaQuery.of(context).size;
    var positionRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 51),
        width: size.width - 38,
        height: size.width - 38);

    return Stack(children: [
      QrScannerZxingView(onDetect: (scannedData) {
        onDetect.call(scannedData);
      }),
      ClipPath(
          clipper: OverlayClipper(),
          child: Opacity(
              opacity: 0.3,
              child: ColoredBox(
                  color: backgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [Spacer()],
                  )))),
      if (status == _ScanStatus.success)
        Positioned.fromRect(
            rect: positionRect,
            child: Icon(
              Icons.check_circle,
              size: 200,
              color: Colors.green.shade400,
            )),
      if (status == _ScanStatus.error)
        Positioned.fromRect(
            rect: positionRect,
            child: Icon(
              Icons.error,
              size: 200,
              color: Colors.red.shade400,
            )),
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

  // will be used later
  // ignore: unused_field
  CredentialData? _credentialData;
  _ScanStatus _status = _ScanStatus.looking;

  void setError() {
    _credentialData = null;
    _scannedString = null;
    _status = _ScanStatus.error;

    Future.delayed(const Duration(milliseconds: 2000), () {
      resetError();
    });
  }

  void resetError() {
    setState(() {
      _credentialData = null;
      _scannedString = null;
      _status = _ScanStatus.looking;
    });
  }

  void handleResult(ScannedData scannedData) {
    if (_status != _ScanStatus.looking) {
      // on success and error ignore reported codes
      return;
    }
    setState(() {
      if (scannedData.data.isNotEmpty) {
        var code = scannedData.data;
        try {
          var parsedCredential = CredentialData.fromUri(Uri.parse(code));
          _credentialData = parsedCredential;
          _scannedString = code;
          _status = _ScanStatus.success;

          Future.delayed(const Duration(milliseconds: 800), () {
            BuildContext dialogContext =
                NavigationService.navigatorKey.currentContext!;
            if (Navigator.of(dialogContext).canPop()) {
              // prevent several callbacks
              Navigator.of(dialogContext).pop(_scannedString);
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
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Scan QR code'),
              leading: BackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: Stack(children: [
              MobileScannerWrapper(
                status: _status,
                onDetect: (scannedData) => handleResult(scannedData),
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(children: [
                        const SizedBox(
                          height: 32,
                        ),
                        if (_status == _ScanStatus.looking)
                          Text('Looking for a code...',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  ?.copyWith(color: Colors.black)),
                        if (_status == _ScanStatus.success)
                          Text('Found a valid code',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  ?.copyWith(color: Colors.white)),
                        if (_status == _ScanStatus.error)
                          Text('This code is not valid, try again.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6
                                  ?.copyWith(color: Colors.white)),
                      ]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MaterialButton(
                            color: Colors.white38,
                            onPressed: () {
                              Navigator.of(context).pop('');
                            },
                            child: const Text('Add manually'),
                          )
                        ],
                      )
                    ],
                  )),
            ])));
  }
}
