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

import '../generated/l10n/app_localizations.dart';

class Serial extends StatefulWidget {
  final int serial;
  final AppLocalizations l10n;

  const Serial({required this.serial, required this.l10n, super.key});

  @override
  State<Serial> createState() => _SerialState();
}

class _SerialState extends State<Serial> {
  bool _obscureText = true;
  double _measureTextWidth(String text, TextStyle? style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _obscureText = false;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _obscureText = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final revealed = widget.l10n.l_serial_number(widget.serial);
    
  final obscured = widget.l10n.l_serial_number(widget.serial).replaceAllMapped(
    RegExp(widget.serial.toString()),
    (match) => '*' * match.group(0)!.length,
  );

    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _measureTextWidth(
            revealed,
            textStyle,
          ), // Fixed width based on full text
          child: Text(
            _obscureText ? obscured : revealed,
            style: textStyle,
            overflow: TextOverflow.clip,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          child: Icon(
            _obscureText ? Icons.visibility_off : Icons.remove_red_eye,
            size: 20.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
