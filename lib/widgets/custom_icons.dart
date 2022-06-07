import 'dart:math';

import 'package:flutter/material.dart';

final Widget pushPinStrokeIcon = Builder(builder: (context) {
  return CustomPaint(
    painter: _StrikethroughPainter(IconTheme.of(context).color ?? Colors.black),
    child: ClipPath(
        clipper: _StrikethroughClipper(), child: const Icon(Icons.push_pin)),
  );
});

class _StrikethroughClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path()
      ..moveTo(0, 2)
      ..lineTo(0, size.height)
      ..lineTo(size.width - 2, size.height)
      ..lineTo(0, 2)
      ..moveTo(2, 0)
      ..lineTo(size.width, size.height - 2)
      ..lineTo(size.width, 0)
      ..lineTo(2, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _StrikethroughPainter extends CustomPainter {
  final Color color;
  _StrikethroughPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3;

    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.15),
        Offset(size.width * 0.8, size.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

final Widget nfcIcon = Builder(builder: (context) {
  final theme = IconTheme.of(context);
  return CustomPaint(
    size: Size.square(theme.size ?? 24),
    painter: _NfcIconPainter(theme.color ?? Colors.black),
  );
});

class _NfcIconPainter extends CustomPainter {
  final Color color;
  _NfcIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 4;
    const sweep = pi / 4;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = step / 2;

    final rect =
        Offset(size.width * -1.7, 0) & Size(size.width * 2, size.height);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(rect.inflate(i * step), -sweep / 2, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
