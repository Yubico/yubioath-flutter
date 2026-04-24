/*
 * Copyright (C) 2026 Yubico.
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

import '../core/state.dart';

/// Draws a 1px foreground border around [child] when [focusNode] has focus,
/// using [color] (or [ColorScheme.primary] when omitted).
///
/// The border is never drawn on Android.
class FocusBorder extends StatelessWidget {
  final FocusNode focusNode;
  final Widget child;

  /// Border shape. Defaults to [BoxShape.rectangle].
  final BoxShape shape;

  /// Corner radius applied when [shape] is [BoxShape.rectangle].
  /// Ignored for [BoxShape.circle].
  final BorderRadiusGeometry? borderRadius;

  /// Overrides the border color. Defaults to [ColorScheme.primary].
  final Color? color;

  const FocusBorder({
    super.key,
    required this.focusNode,
    required this.child,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: shape,
          border: !isAndroid && focusNode.hasFocus
              ? Border.all(color: resolvedColor, width: 1)
              : null,
          borderRadius: shape == BoxShape.circle ? null : borderRadius,
        ),
        child: child!,
      ),
      child: child,
    );
  }
}
