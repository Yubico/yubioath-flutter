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

/// Wraps a child and automatically scrolls to bring the focused widget
/// into view when the keyboard appears, disappears, or the screen rotates.
///
/// Only active on Android. On desktop platforms this is a no-op passthrough.
/// Must be placed inside a [SingleChildScrollView] (or any [Scrollable]).
class EnsureFocusVisible extends StatefulWidget {
  final Widget child;
  const EnsureFocusVisible({super.key, required this.child});

  @override
  State<EnsureFocusVisible> createState() => _EnsureFocusVisibleState();
}

class _EnsureFocusVisibleState extends State<EnsureFocusVisible>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (isAndroid) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Called when keyboard appears/disappears or on rotation.
    // Delay to let the layout settle after the resize.
    Future.delayed(const Duration(milliseconds: 400), _scrollToFocus);
  }

  void _scrollToFocus() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null || !mounted) return;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      // When resizeToAvoidBottomInset is false, the viewport extends behind
      // the keyboard. ensureVisible thinks the widget is already visible.
      // Manually check and scroll so the widget is above the keyboard.
      final focusedObject = focusedContext.findRenderObject();
      if (focusedObject is RenderBox && focusedObject.attached) {
        final offset = focusedObject.localToGlobal(Offset.zero);
        final widgetBottom = offset.dy + focusedObject.size.height;
        final screenHeight = MediaQuery.of(context).size.height;
        final visibleBottom = screenHeight - keyboardHeight;

        if (widgetBottom > visibleBottom - 16) {
          // Widget is behind or too close to the keyboard — scroll it up.
          final scrollable = Scrollable.maybeOf(focusedContext);
          if (scrollable != null) {
            final position = scrollable.position;
            final overlap = widgetBottom - visibleBottom + 16;
            final target = (position.pixels + overlap).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            );
            position.animateTo(
              target,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    } else {
      Scrollable.ensureVisible(
        focusedContext,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAndroid) return widget.child;
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          Future.delayed(const Duration(milliseconds: 400), _scrollToFocus);
        }
      },
      child: widget.child,
    );
  }
}
