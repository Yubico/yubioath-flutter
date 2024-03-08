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

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

final Widget pushPinStrokeIcon = Builder(builder: (context) {
  return CustomPaint(
    painter: _StrikethroughPainter(IconTheme.of(context).color ?? Colors.black),
    child: ClipPath(
        clipper: _StrikethroughClipper(), child: const Icon(Symbols.push_pin)),
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
