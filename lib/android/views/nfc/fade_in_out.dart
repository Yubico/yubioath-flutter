import 'dart:async';

import 'package:flutter/material.dart';

/// Repeatedly fades in and out its child
class FadeInOut extends StatefulWidget {
  final Widget child;
  final double minOpacity;
  final double maxOpacity;
  final Duration pulseDuration;
  final Duration delayBetweenShakesDuration;
  final Duration startupDelay;

  const FadeInOut(
      {super.key,
      required this.child,
      this.minOpacity = 0.0,
      this.maxOpacity = 1.0,
      this.pulseDuration = const Duration(milliseconds: 300),
      this.delayBetweenShakesDuration = const Duration(seconds: 3),
      this.startupDelay = Duration.zero});

  @override
  State<FadeInOut> createState() => _FadeInOutState();
}

class _FadeInOutState extends State<FadeInOut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer delayTimer;

  bool playingForward = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration:
            Duration(milliseconds: widget.pulseDuration.inMilliseconds ~/ 2));

    _controller.addListener(() async {
      if (_controller.isCompleted || _controller.isDismissed) {
        playingForward = !playingForward;
        var delay = Duration.zero;
        if (playingForward == true) {
          delay = widget.delayBetweenShakesDuration;
        }

        if (delayTimer.isActive) {
          delayTimer.cancel();
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
        Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(
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
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
