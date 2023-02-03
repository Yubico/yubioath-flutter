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

import 'progress_circle.dart';

class CircleTimer extends StatefulWidget {
  final int validFromMs;
  final int validToMs;
  const CircleTimer(this.validFromMs, this.validToMs, {super.key});

  @override
  State<StatefulWidget> createState() => _CircleTimerState();
}

class _CircleTimerState extends State<CircleTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animator;
  late Tween<double> _tween;
  late Animation<double> _progress;

  void _animate() {
    var period = widget.validToMs - widget.validFromMs;
    var now = DateTime.now().millisecondsSinceEpoch;
    _tween.begin = 1.0 - (now - widget.validFromMs) / period;
    var timeLeft = widget.validToMs - now;
    if (timeLeft > 0) {
      _animator.duration = Duration(milliseconds: timeLeft.toInt());
    } else {
      _animator.duration = Duration.zero;
    }
    _animator.forward();
  }

  @override
  void initState() {
    super.initState();

    _animator = AnimationController(vsync: this);
    _tween = Tween(end: 0);
    _progress = _tween.animate(_animator)
      ..addListener(() {
        setState(() {});
      });

    _animate();
  }

  @override
  void didUpdateWidget(CircleTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animator.reset();
    _animate();
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressCircle(
        IconTheme.of(context).color ?? Colors.grey.shade600, _progress.value);
  }
}
