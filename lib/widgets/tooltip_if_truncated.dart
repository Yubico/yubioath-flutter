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

import 'package:flutter/material.dart';

class TooltipIfTruncated extends StatelessWidget {
  final String text;
  final TextStyle style;
  final String? tooltip;
  final int maxLines;
  final TextOverflow overflow;
  const TooltipIfTruncated(
      {super.key,
      required this.text,
      required this.style,
      this.tooltip,
      this.maxLines = 1,
      this.overflow = TextOverflow.fade});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidget = Text(
          text,
          textAlign: TextAlign.left,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: maxLines != 1,
          style: style,
        );
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
        )..layout(minWidth: 0, maxWidth: constraints.maxWidth);
        return textPainter.didExceedMaxLines
            ? Tooltip(
                margin: const EdgeInsets.all(16),
                message: tooltip ?? text,
                child: textWidget,
              )
            : textWidget;
      },
    );
  }
}
