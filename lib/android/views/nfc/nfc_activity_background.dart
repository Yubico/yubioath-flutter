import 'dart:math';

import 'package:flutter/material.dart';

class NfcActivityBackground extends StatefulWidget {
  final double opacity;
  final Color backgroundColor;
  final Color foregroundColor;

  const NfcActivityBackground(
      {super.key,
      this.opacity = 1.0,
      this.backgroundColor = Colors.transparent,
      this.foregroundColor = Colors.black});

  @override
  State<NfcActivityBackground> createState() => _NfcActivityBackgroundState();
}

class _NfcActivityBackgroundState extends State<NfcActivityBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller
      ..stop()
      ..reset()
      ..repeat(period: const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          AnimatedOpacity(
        opacity: widget.opacity,
        duration: const Duration(milliseconds: 500),
        child: CustomPaint(
            painter: _NfcActivityBackgroundPainter(
              _controller,
              widget.foregroundColor,
              widget.backgroundColor,
            ),
            child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                )),
      ),
    );
  }
}

class _NfcActivityBackgroundPainter extends CustomPainter {
  final Animation<double> _animation;
  final Color _foregroundColor;
  final Color _backgroundColor;

  _NfcActivityBackgroundPainter(this._animation, this._foregroundColor, this._backgroundColor)
      : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 3.0)).clamp(0.0, 1.0);
    Color color = _foregroundColor.withOpacity(opacity);

    double size = rect.width / 2;
    double area = size * size;
    double radius = sqrt(area * value / 4);

    final Paint paint = Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    canvas.drawRect(rect, Paint()..color = _backgroundColor);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(_NfcActivityBackgroundPainter oldDelegate) {
    return true;
  }
}
