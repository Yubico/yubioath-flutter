/*
 * Copyright (C) 2022 Yubico.
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

class ProgressCircle extends StatelessWidget {
  final Color color;
  final double progress;
  const ProgressCircle(this.color, this.progress, {super.key});

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
