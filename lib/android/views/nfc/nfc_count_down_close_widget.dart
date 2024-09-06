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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state.dart';
import 'models.dart';
import 'nfc_activity_overlay.dart';
import 'nfc_content_widget.dart';

NfcEventCommand countDownClose({
  int closeInSec = 3,
  String? title,
  String? subtitle,
  Widget? icon,
}) =>
    setNfcView(_CountDownCloseWidget(
      closeInSec: closeInSec,
      child: NfcContentWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
      ),
    ));

class _CountDownCloseWidget extends ConsumerStatefulWidget {
  final int closeInSec;
  final Widget child;

  const _CountDownCloseWidget({required this.child, required this.closeInSec});

  @override
  ConsumerState<_CountDownCloseWidget> createState() =>
      _CountDownCloseWidgetState();
}

class _CountDownCloseWidgetState extends ConsumerState<_CountDownCloseWidget> {
  late int counter;
  late Timer? timer;
  bool shouldHide = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(androidNfcActivityProvider, (previous, current) {
      if (current == NfcActivity.ready) {
        timer?.cancel();
        hideNow();
      }
    });

    return Stack(
      fit: StackFit.loose,
      children: [
        Center(child: widget.child),
        Positioned(
          bottom: 0,
          right: 0,
          child: counter > 0
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Closing in $counter'),
                )
              : const SizedBox(),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    counter = widget.closeInSec;
    timer = Timer(const Duration(seconds: 0), onTimer);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void onTimer() async {
    timer?.cancel();
    setState(() {
      counter--;
    });

    if (counter > 0) {
      timer = Timer(const Duration(seconds: 1), onTimer);
    } else {
      hideNow();
    }
  }

  void hideNow() {
    ref.read(nfcEventCommandNotifier.notifier).sendCommand(hideNfcView());
  }
}
