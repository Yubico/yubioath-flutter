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
import '../../tap_request_dialog.dart';
import 'models.dart';
import 'nfc_activity_overlay.dart';

final _log = Logger('android.nfc_activity_command_listener');

final nfcEventCommandListener =
    Provider<_NfcEventCommandListener>((ref) => _NfcEventCommandListener(ref));

class _NfcEventCommandListener {
  final ProviderRef _ref;
  ProviderSubscription<NfcEvent>? listener;

  _NfcEventCommandListener(this._ref);

  void startListener(BuildContext context) {
    listener?.close();
    listener = _ref.listen(nfcEventNotifier, (previous, action) {
      _log.debug('Change in command for Overlay: $previous -> $action');
      switch (action) {
        case (NfcSetViewEvent a):
          if (!visible && a.showIfHidden) {
            _show(context, a.child);
          } else {
            _ref.read(nfcViewNotifier.notifier).update(a.child);
          }
          break;
        case (NfcHideViewEvent e):
          _hide(context, e.delay);
          break;
      }
    });
  }

  void _show(BuildContext context, Widget child) async {
    final notifier = _ref.read(nfcViewNotifier.notifier);
    notifier.update(child);
    if (!visible) {
      visible = true;
      final result = await showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return const NfcBottomSheet();
          });
      if (result == null) {
        // the modal sheet was cancelled by Back button, close button or dismiss
        _ref.read(androidDialogProvider.notifier).cancelDialog();
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

  bool get visible => _ref.read(nfcViewNotifier.select((s) => s.visible));

  set visible(bool showing) =>
      _ref.read(nfcViewNotifier.notifier).setShowing(showing);
}
