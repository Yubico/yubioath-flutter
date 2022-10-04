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

class CutoutOverlay extends StatelessWidget {
  final int marginPct;
  const CutoutOverlay({Key? key, required this.marginPct}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: CustomPaint(
          painter: CutoutPainter(marginPct: marginPct),
        ));
  }
}

class CutoutPainter extends CustomPainter {
  final int marginPct;
  CutoutPainter({required this.marginPct});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black54;
    final strokePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final shorterDim = min(size.width, size.height);

    final cutoutWidth = shorterDim - (2 * shorterDim * marginPct / 100);

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
