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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/app/views/horizontal_shake.dart';

import '../../../theme.dart';

/// Default icon for [NfcActivityWidget]
class NfcActivityIcon extends StatelessWidget {
  final NfcActivity nfcActivity;

  const NfcActivityIcon(this.nfcActivity, {super.key});

  @override
  Widget build(BuildContext context) => switch (nfcActivity) {
        NfcActivity.ready => const HorizontalShake(
            startupDelay: Duration(seconds: 4),
            child: _NfcIconWithOpacity(0.8)),
        NfcActivity.processingStarted => Stack(
            fit: StackFit.loose,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 7.0,
                  sigmaY: 7.0,
                  tileMode: TileMode.decal,
                ),
                child: const Opacity(
                  opacity: 0.6,
                  child: _NfcIcon(
                    color: accentGreen,
                  ),
                ),
              ),
              const _NfcIcon(),
            ],
          ),

        NfcActivity.processingInterrupted =>
          const _NfcIconWrapper(Icons.warning_amber_rounded),
        _ => const _NfcIcon(),
      };
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

class _NfcIconWrapper extends StatelessWidget {
  final IconData _iconData;

  const _NfcIconWrapper(this._iconData);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext buildContext, BoxConstraints constraints) =>
            Icon(
              _iconData,
              size: constraints.biggest.width,
            ));
  }
}

class _NfcIcon extends StatelessWidget {
  final Color? color;

  const _NfcIcon({this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return LayoutBuilder(
      builder: (BuildContext buildContext, BoxConstraints constraints) =>
          CustomPaint(
        size: Size.copy(constraints.biggest),
        painter: _NfcIconPainter(color ?? theme.color ?? Colors.black),
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
