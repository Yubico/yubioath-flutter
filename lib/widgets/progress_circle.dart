import 'dart:math';

import 'package:flutter/material.dart';

class ProgressCircle extends StatelessWidget {
  final Color color;
  final double progress;
  const ProgressCircle(this.color, this.progress, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CirclePainter(color, progress),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color color;
  final double progress;
  _CirclePainter(this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    var radius = min(size.width, size.height) / 2;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      -pi / 2,
      -progress * 2 * pi,
      true,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
