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
    Scrollable.ensureVisible(
      focusedContext,
      duration: const Duration(milliseconds: 200),
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
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
