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

import 'dart:async';

import 'package:flutter/material.dart';

class Toast extends StatefulWidget {
  final String message;
  final Duration duration;
  final void Function() onComplete;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  const Toast(
    this.message,
    this.duration, {
    required this.onComplete,
    this.backgroundColor,
    this.textStyle,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ToastState();
}

class _ToastState extends State<Toast> with SingleTickerProviderStateMixin {
  late AnimationController _animator;
  late Tween<double> _tween;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _animator = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _tween = Tween(begin: 0, end: 1);
    _opacity = _tween.animate(_animator)
      ..addListener(() {
        setState(() {});
      });

    _animate();
  }

  void _animate() async {
    await _animator.forward();
    if (mounted) {
      await Future.delayed(widget.duration);
    }
    if (mounted) {
      await _animator.reverse();
    }
    widget.onComplete();
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Material(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        color: widget.backgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.message,
              style: widget.textStyle,
            ),
          ),
        ),
      ),
    );
  }
}

void Function() showToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final bool isThemeDark = theme.brightness == Brightness.dark;
  final Color backgroundColor = isThemeDark
      ? colorScheme.onSurface
      : Color.alphaBlend(
          colorScheme.onSurface.withOpacity(0.80), colorScheme.surface);
  final textStyle =
      ThemeData(brightness: isThemeDark ? Brightness.light : Brightness.dark)
          .textTheme
          .titleMedium;

  OverlayEntry? entry;
  void close() {
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  entry = OverlayEntry(builder: (context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 50,
            width: 400,
            margin: const EdgeInsets.all(8),
            child: Toast(
              message,
              duration,
              backgroundColor: backgroundColor,
              textStyle: textStyle,
              onComplete: close,
            ),
          ),
        ),
      ),
    );
  });
  Timer.run(() {
    Overlay.of(context).insert(entry!);
  });

  return close;
}
