/*
 * Copyright (C) 2023 Yubico.
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yubico_authenticator/android/state.dart';

/// Default icon for [NfcActivityWidget]
class NfcActivityIcon extends StatelessWidget {
  final NfcActivity nfcActivity;

  const NfcActivityIcon(this.nfcActivity, {super.key});

  @override
  Widget build(BuildContext context) => switch (nfcActivity) {
        NfcActivity.notActive ||
        NfcActivity.ready =>
          const _NfcIconWithOpacity(0.5),
        NfcActivity.tagPresent => const _NfcIconWithOpacity(0.8),
        NfcActivity.processingStarted => const _NfcIconProcessing(),
        NfcActivity.processingFinished => const _NfcIconWithOpacity(0.5),
        NfcActivity.processingInterrupted => const _NfcIconWithOpacity(0.5),
      };
}

class _NfcIconProcessing extends StatefulWidget {

  const _NfcIconProcessing();

  @override
  State<StatefulWidget> createState() => _NfcIconProcessingState();
}

class _NfcIconProcessingState extends State<_NfcIconProcessing>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    animation = CurvedAnimation(parent: _controller, curve: Curves.linear)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AnimatedNfcIcon(animation: animation);
}

class _AnimatedNfcIcon extends AnimatedWidget {
  const _AnimatedNfcIcon({required Animation<double> animation})
      : super(listenable: animation);

  static final _opacityTween = Tween<double>(begin: 0.0, end: 1.0);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Opacity(
      opacity: _opacityTween.evaluate(animation),
      child: const _NfcIcon(),
    );
  }
}

class _NfcIconWithOpacity extends StatelessWidget {
  final double opacity;

  const _NfcIconWithOpacity(this.opacity);

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: const _NfcIcon(),
      );
}

class _NfcIcon extends StatelessWidget {
  const _NfcIcon();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return LayoutBuilder(
      builder: (BuildContext buildContext, BoxConstraints constraints) =>
          CustomPaint(
        size: Size.copy(constraints.biggest),
        painter: _NfcIconPainter(theme.color ?? Colors.black),
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
