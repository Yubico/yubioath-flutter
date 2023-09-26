import 'dart:async';

import 'package:flutter/material.dart';

class HorizontalShake extends StatefulWidget {
  final Widget child;
  final double shakeAmount;
  final int shakeCount;
  final Duration shakeDuration;
  final Duration delayBetweenShakesDuration;
  final Duration startupDelay;

  const HorizontalShake(
      {super.key,
      required this.child,
      this.shakeAmount = 2,
      this.shakeCount = 3,
      this.shakeDuration = const Duration(milliseconds: 50),
      this.delayBetweenShakesDuration = const Duration(seconds: 3),
      this.startupDelay = const Duration(seconds: 0)});

  @override
  State<HorizontalShake> createState() => _HorizontalShakeState();
}

class _HorizontalShakeState extends State<HorizontalShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer delayTimer;

  int _shakeCounter = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.shakeDuration);

    _controller.addListener(() async {
      if (_controller.isCompleted || _controller.isDismissed) {
        var delay = const Duration(milliseconds: 0);
        if (_shakeCounter++ > widget.shakeCount * 2) {
          delay = widget.delayBetweenShakesDuration;
          _shakeCounter = 0;
        }

        delayTimer = Timer(delay, () async {
          if (_controller.isCompleted) {
            await _controller.reverse();
          } else if (_controller.isDismissed) {
            await _controller.forward();
          }
        });
      }
    });

    _animation =
        Tween<double>(begin: 0, end: widget.shakeAmount)
            .animate(
      CurvedAnimation(parent: _controller, curve: Curves.ease),
    );

    delayTimer = Timer(widget.startupDelay, () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    delayTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}
