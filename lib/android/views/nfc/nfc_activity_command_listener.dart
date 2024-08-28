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

import '../../../app/models.dart';
import '../../tap_request_dialog.dart';
import 'nfc_activity_overlay.dart';

final nfcActivityCommandListener = Provider<_NfcActivityCommandListener>(
    (ref) => _NfcActivityCommandListener(ref));

class _NfcActivityCommandListener {
  final ProviderRef _ref;
  ProviderSubscription<NfcActivityWidgetAction>? listener;

  _NfcActivityCommandListener(this._ref);

  void startListener(BuildContext context) {
    debugPrint('XXX Started listener');
    listener?.close();
    listener = _ref.listen(nfcActivityCommandNotifier.select((c) => c.action),
        (previous, action) {
      debugPrint(
          'XXX Change in command for Overlay: $previous -> $action in context: $context');
      switch (action) {
        case (NfcActivityWidgetActionShowWidget a):
          _show(context, a.child);
          break;
        case (NfcActivityWidgetActionSetWidgetData a):
          _ref.read(nfcActivityWidgetNotifier.notifier).update(a.child);
          break;
        case (NfcActivityWidgetActionHideWidget _):
          _hide(context);
          break;
        case (NfcActivityWidgetActionCancelWidget _):
          _ref.read(androidDialogProvider.notifier).cancelDialog();
          _hide(context);
          break;
      }
    });
  }

  void _show(BuildContext context, Widget child) async {
    final widgetNotifier = _ref.read(nfcActivityWidgetNotifier.notifier);
    widgetNotifier.update(child);
    if (!_ref.read(nfcActivityWidgetNotifier.select((s) => s.isShowing))) {
      widgetNotifier.setShowing(true);
      final result = await showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return const NfcBottomSheet();
          });

      debugPrint('XXX result is: $result');
      if (result == null) {
        // the modal sheet was cancelled by Back button, close button or dismiss
        _ref.read(androidDialogProvider.notifier).cancelDialog();
      }
      widgetNotifier.setShowing(false);
    }
  }

  void _hide(BuildContext context) {
    if (_ref.read(nfcActivityWidgetNotifier.select((s) => s.isShowing))) {
      Navigator.of(context).pop('AFTER OP');
      _ref.read(nfcActivityWidgetNotifier.notifier).setShowing(false);
    }
  }
}
