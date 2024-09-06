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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'models.dart';

final nfcEventNotifier =
    NotifierProvider<_NfcEventNotifier, NfcEvent>(_NfcEventNotifier.new);

class _NfcEventNotifier extends Notifier<NfcEvent> {
  @override
  NfcEvent build() {
    return const NfcEvent();
  }

  void send(NfcEvent event) {
    state = event;
  }
}

final nfcViewNotifier =
    NotifierProvider<_NfcViewNotifier, NfcView>(_NfcViewNotifier.new);

class _NfcViewNotifier extends Notifier<NfcView> {
  @override
  NfcView build() {
    return NfcView(child: const SizedBox());
  }

  void update(Widget child) {
    state = state.copyWith(child: child);
  }

  void setShowing(bool value) {
    state = state.copyWith(visible: value);
  }

  void setDialogProperties({bool? showCloseButton}) {
    state =
        state.copyWith(hasCloseButton: showCloseButton ?? state.hasCloseButton);
  }
}

class NfcBottomSheet extends ConsumerWidget {
  const NfcBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widget = ref.watch(nfcViewNotifier.select((s) => s.child));
    final showCloseButton =
        ref.watch(nfcViewNotifier.select((s) => s.hasCloseButton));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(fit: StackFit.passthrough, children: [
          if (showCloseButton)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Symbols.close, fill: 1, size: 24)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: widget,
          )
        ]),
        const SizedBox(height: 32),
      ],
    );
  }
}
