/*
 * Copyright (C) 2024 Yubico.
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

class Pulsing extends StatefulWidget {
  final Widget child;

  const Pulsing({super.key, required this.child});

  @override
  State<Pulsing> createState() => _PulsingState();
}

class _PulsingState extends State<Pulsing> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animationScale;

  late final CurvedAnimation curvedAnimation;

  static const _duration = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Transform.scale(scale: animationScale.value, child: widget.child),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: _duration,
      vsync: this,
    );
    curvedAnimation = CurvedAnimation(
        parent: controller, curve: Curves.easeIn, reverseCurve: Curves.easeOut);
    animationScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(curvedAnimation)
      ..addListener(() {
        setState(() {});
      });

    controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
