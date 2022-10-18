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

class DelayedVisibility extends StatefulWidget {
  final Duration delay;
  final Widget child;

  /// Makes child visible after delay
  const DelayedVisibility(
      {super.key, required this.delay, required this.child});

  @override
  State<StatefulWidget> createState() => _DelayedVisibilityState();
}

class _DelayedVisibilityState extends State<DelayedVisibility> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.delay, (timer) {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
      timer.cancel();
      _timer = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _visible,
      maintainState: true,
      maintainAnimation: true,
      child: widget.child,
    );
  }
}
