import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/core/state.dart';

const widgetColor = Colors.amber;
const backgroundColor = Colors.cyan;
const widgetWidth = 100.0;
const iconWidth = widgetWidth / 1.8;

final _logger = Logger('nfc_activity_overlay');

class NfcActivityBackgroundPainter extends CustomPainter {
  final Animation<double> _animation;

  NfcActivityBackgroundPainter(this._animation) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 3.0)).clamp(0.0, 1.0);
    Color color = backgroundColor.withOpacity(opacity);

    double size = rect.width / 2;
    double area = size * size;
    double radius = sqrt(area * value / 4);

    final Paint paint = Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(NfcActivityBackgroundPainter oldDelegate) {
    return true;
  }
}

class NfcActivityBackground extends StatefulWidget {
  final double opacity;
  const NfcActivityBackground({super.key, this.opacity = 1.0});

  @override
  NfcActivityBackgroundState createState() => NfcActivityBackgroundState();
}

class NfcActivityBackgroundState extends State<NfcActivityBackground>
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
    return AnimatedOpacity(
      opacity: widget.opacity,
      duration: const Duration(milliseconds: 500),
      child: CustomPaint(
        painter: NfcActivityBackgroundPainter(_controller),
        child: const SizedBox(
          width: widgetWidth,
          height: widgetWidth,
        ),
      ),
    );
  }
}

class NfcActivityIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const NfcActivityIcon({
    super.key,
    this.color = widgetColor,
    this.size = iconWidth,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size.square(size),
        painter: _NfcIconPainter(color),
      ),
    );
  }
}

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

class NfcActivityWidget extends StatelessWidget {
  final NfcActivity nfcActivity;

  const NfcActivityWidget({super.key, required this.nfcActivity});

  @override
  Widget build(BuildContext context) {

    final successfulProcessing = nfcActivity == NfcActivity.processingFinished;
    final processingError = nfcActivity == NfcActivity.processingInterrupted;
    final backgroundOpacity = nfcActivity == NfcActivity.processingStarted
        ? 0.6 : 0.0;
    final opacity = nfcActivity == NfcActivity.ready
        ? 0.2
        : nfcActivity == NfcActivity.tagPresent
            ? 0.7
            : successfulProcessing || processingError
              ? 0.3
              : 0.7;

    _logger.info('Successful processing: $successfulProcessing  ProcessingError: $processingError BackgroundOpacity: $backgroundOpacity opacity: $opacity');

    return Stack(
      alignment: Alignment.center,
      children: [
        NfcActivityBackground(opacity: backgroundOpacity,),
        NfcActivityIcon(opacity: opacity,),
        if (successfulProcessing)
          const Icon(Icons.check_rounded, color: Colors.green, size: 48,),
        if (processingError)
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48,),
        const SizedBox(width: widgetWidth, height: widgetWidth,)
      ],
    );
  }
}

class NfcActivityOverlay extends ConsumerWidget {
  final Widget child;

  const NfcActivityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktop) {
      return child;
    }

    final nfcActivity = ref.watch(androidNfcActivityProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        child,
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              verticalDirection: VerticalDirection.down,
              children: [
                NfcActivityWidget(nfcActivity: nfcActivity),
                const SizedBox(
                  height: 56,
                )
              ],
            ),
            const SizedBox(
              width: 16,
            )
          ],
        )
      ]),
    );
  }
}
