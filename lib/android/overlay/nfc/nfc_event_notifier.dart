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
import 'package:logging/logging.dart';

import '../../../app/logging.dart';
import '../../../app/state.dart';
import 'nfc_overlay.dart';
import 'views/nfc_overlay_widget.dart';

final _log = Logger('android.nfc_event_notifier');

class NfcEvent {
  const NfcEvent();
}

class NfcHideViewEvent extends NfcEvent {
  final Duration delay;

  const NfcHideViewEvent({this.delay = Duration.zero});
}

class NfcSetViewEvent extends NfcEvent {
  final Widget child;
  final bool showIfHidden;

  const NfcSetViewEvent({required this.child, this.showIfHidden = true});
}

final nfcEventNotifier = NotifierProvider<_NfcEventNotifier, NfcEvent>(
  _NfcEventNotifier.new,
);

class _NfcEventNotifier extends Notifier<NfcEvent> {
  @override
  NfcEvent build() {
    return const NfcEvent();
  }

  void send(NfcEvent event) {
    state = event;
  }
}

final nfcEventNotifierListener = Provider<_NfcEventNotifierListener>(
  (ref) => _NfcEventNotifierListener(ref),
);

class _NfcEventNotifierListener {
  final Ref _ref;
  ProviderSubscription<NfcEvent>? listener;

  _NfcEventNotifierListener(this._ref);

  void startListener(BuildContext context) {
    listener?.close();
    listener = _ref.listen(nfcEventNotifier, (previous, action) {
      _log.debug('Event change: $previous -> $action');
      switch (action) {
        case (NfcSetViewEvent a):
          if (!visible && a.showIfHidden) {
            _show(context, a.child);
          } else {
            _ref
                .read(nfcOverlayWidgetProperties.notifier)
                .update(child: a.child);
          }
          break;
        case (NfcHideViewEvent e):
          _hide(context, e.delay);
          break;
      }
    });
  }

  void _show(BuildContext context, Widget child) async {
    final notifier = _ref.read(nfcOverlayWidgetProperties.notifier);
    notifier.update(child: child);
    if (!visible) {
      visible = true;
      final result = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return const NfcOverlayWidget();
        },
      );
      if (result == null) {
        // the modal sheet was cancelled by Back button, close button or dismiss
        _ref.read(nfcOverlay.notifier).onCancel();
      }
      visible = false;
    }
  }

  void _hide(BuildContext context, Duration timeout) {
    Future.delayed(timeout, () {
      _ref.read(withContextProvider)((context) async {
        if (visible) {
          Navigator.of(context).pop('HIDDEN');
          visible = false;
        }
      });
    });
  }

  bool get visible =>
      _ref.read(nfcOverlayWidgetProperties.select((s) => s.visible));

  set visible(bool visible) =>
      _ref.read(nfcOverlayWidgetProperties.notifier).update(visible: visible);
}
