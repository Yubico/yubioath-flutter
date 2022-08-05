import 'package:flutter/material.dart';

import 'qr_scanner_scan_status.dart';
import 'qr_scanner_util.dart';

/// Return the rounded rect which represents the scanner area for the background
/// overlay and the stroke
RRect _getScannerAreaRRect(Size size) {
  double scannerAreaWidth = getScannerAreaWidth(size);
  var scannerAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scannerAreaWidth,
      height: scannerAreaWidth);

  return RRect.fromRectAndRadius(
      scannerAreaRect, const Radius.circular(scannerAreaRadius));
}

// CustomPainter which strokes the scannerArea
class _ScannerAreaStrokePainter extends CustomPainter {
  final Color _strokeColor;

  _ScannerAreaStrokePainter(this._strokeColor) : super();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    Path path = Path()..addRRect(_getScannerAreaRRect(size));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// clips the scanner area rounded rect of specific Size
class _ScannerAreaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(_getScannerAreaRRect(size))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class QRScannerOverlay extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;

  const QRScannerOverlay({
    super.key,
    required this.status,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    var size = screenSize;

    return Stack(children: [
      /// clip scanner area "hole" into a darkened background
      ClipPath(
          clipper: _ScannerAreaClipper(),
          child: Opacity(
              opacity: 0.6,
              child: ColoredBox(
                  color: Colors.black,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [Spacer()],
                  )))),

      /// draw a stroke around the scanner area
      Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomPaint(
            painter: _ScannerAreaStrokePainter(status == ScanStatus.error
                ? Colors.red.shade400
                : Colors.green.shade400),
          ),
        ],
      ),

      /// extra icon when successful scan occurred
      if (status == ScanStatus.success)
        Positioned.fromRect(
            rect: Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2),
                width: size.width,
                height: size.height),
            child: Icon(
              Icons.check_circle,
              size: 200,
              color: Colors.green.shade400,
            )),
    ]);
  }
}
