/*
 * Copyright (C) 2022-2026 Yubico.
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

import 'qr_scanner_scan_status.dart';

const double _kBorderRadius = 24.0;
const double _kBorderWidth = 8.0;

/// Paints a solid background with a rounded-rect hole punched out.
class QRScannerCutoutBackground extends StatelessWidget {
  final Color backgroundColor;

  const QRScannerCutoutBackground({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CutoutBackgroundPainter(backgroundColor),
      child: const SizedBox.expand(),
    );
  }
}

class _CutoutBackgroundPainter extends CustomPainter {
  final Color _backgroundColor;

  _CutoutBackgroundPainter(this._backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _kBorderWidth / 2;
    final holeRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    // Extend outer rect beyond widget bounds to ensure no camera pixels
    // leak through at edges due to sub-pixel rendering.
    final path = Path()
      ..addRect(Rect.fromLTWH(-2, -2, size.width + 4, size.height + 4))
      ..addRRect(
        RRect.fromRectAndRadius(
          holeRect,
          const Radius.circular(_kBorderRadius - inset),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = _backgroundColor);
  }

  @override
  bool shouldRepaint(covariant _CutoutBackgroundPainter oldDelegate) =>
      oldDelegate._backgroundColor != _backgroundColor;
}

/// Paints a rounded-rect border stroke and optional success/error indicator.
class QRScannerBorder extends StatelessWidget {
  final ScanStatus status;
  final Color primaryColor;

  const QRScannerBorder({
    super.key,
    required this.status,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ScanStatus.error => Colors.red.shade400,
      ScanStatus.success => Colors.green.shade400,
      ScanStatus.scanning => primaryColor,
    };

    return CustomPaint(
      painter: _BorderPainter(color),
      child: status == ScanStatus.success
          ? Center(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withAlpha(240),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Symbols.check, color: Colors.white, size: 64),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final Color _color;

  _BorderPainter(this._color);

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _kBorderWidth / 2;
    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kBorderWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      const Radius.circular(_kBorderRadius - inset),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      oldDelegate._color != _color;
}
