import 'dart:math';

import 'package:flutter/material.dart';

class CutoutOverlay extends StatelessWidget {
  final int border;
  const CutoutOverlay({Key? key, this.border = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CutoutPainter(border: border),
    );
  }
}

class CutoutPainter extends CustomPainter {
  final int border;
  CutoutPainter({required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black54;
    final strokePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cutoutWidth = min(size.width - border, size.height - border);

    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutWidth,
      height: cutoutWidth,
    );

    final cutOutRRect =
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(5.0));
    final targetPath = Path()..addRRect(cutOutRRect);

    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          targetPath..close(),
        ),
        overlayPaint);

    canvas.drawPath(targetPath, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
