/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'qr_scanner_scan_status.dart';

class QRScannerOverlay extends StatelessWidget {
  final ScanStatus status;
  final Size screenSize;
  final GlobalKey overlayWidgetKey;

  const QRScannerOverlay(
      {super.key,
      required this.status,
      required this.screenSize,
      required this.overlayWidgetKey});

  RRect getOverlayRRect(Size size) {
    final renderBox =
        overlayWidgetKey.currentContext?.findRenderObject() as RenderBox;
    final renderObjectSize = renderBox.size;
    final renderObjectOffset = renderBox.globalToLocal(Offset.zero);

    final double shorterEdge =
        min(renderObjectSize.width, renderObjectSize.height);

    var top = (size.height - shorterEdge) / 2 - 32;

    if (top + renderObjectOffset.dy < 0) {
      top = -renderObjectOffset.dy;
    }

    return RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (size.width - shorterEdge) / 2, top, shorterEdge, shorterEdge),
        const Radius.circular(10));
  }

  @override
  Widget build(BuildContext context) {
    overlayRectProvider(Size size) {
      return getOverlayRRect(size);
    }

    return Stack(fit: StackFit.expand, children: [
      /// clip scanner area "hole" into a darkened background
      ClipPath(
        clipper: _OverlayClipper(overlayRectProvider),
        child: const Opacity(
          opacity: 0.6,
          child: ColoredBox(
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Spacer()],
            ),
          ),
        ),
      ),

      /// draw a stroke around the scanner area
      CustomPaint(
        painter: _OverlayPainter(status, overlayRectProvider),
      ),
    ]);
  }
}

/// Paints a colored stroke and status icon.
/// The stroke area is acquired through passed in rectangle provider.
/// The color is computed from the scan status.
class _OverlayPainter extends CustomPainter {
  final ScanStatus _status;
  final Function(Size) _rectProvider;

  _OverlayPainter(this._status, this._rectProvider) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final color = _status == ScanStatus.error
        ? Colors.red.shade400
        : Colors.green.shade400;
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final RRect overlayRRect = _rectProvider(size);

    Path path = Path()..addRRect(overlayRRect);
    canvas.drawPath(path, paint);

    if (_status == ScanStatus.success) {
      const icon = Icons.check_circle;
      final iconSize =
          overlayRRect.width < 150 ? overlayRRect.width - 5.0 : 150.0;
      TextPainter iconPainter = TextPainter(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      );
      iconPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            color: color.withAlpha(240),
          ));
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        overlayRRect.center.translate(-iconSize / 2, -iconSize / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clips a hole into the background.
/// The clipped area is acquired through passed in rectangle provider.
class _OverlayClipper extends CustomClipper<Path> {
  final Function(Size) _rectProvider;

  _OverlayClipper(this._rectProvider);

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(_rectProvider(size))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
