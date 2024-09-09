/*
 * Copyright (C) 2022-2024 Yubico.
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

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../app/logging.dart';
import '../../../app/state.dart';
import '../../state.dart';
import 'nfc_event_notifier.dart';
import 'views/nfc_content_widget.dart';
import 'views/nfc_overlay_icons.dart';
import 'views/nfc_overlay_widget.dart';

final _log = Logger('android.tap_request_dialog');
const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

final nfcOverlayProvider =
    NotifierProvider<_NfcOverlayProvider, int>(_NfcOverlayProvider.new);

class _NfcOverlayProvider extends Notifier<int> {
  Timer? processingViewTimeout;
  late final l10n = ref.read(l10nProvider);

  @override
  int build() {
    ref.listen(androidNfcState, (previous, current) {
      processingViewTimeout?.cancel();
      final notifier = ref.read(nfcEventNotifier.notifier);

      switch (current) {
        case NfcState.ongoing:
          // the "Hold still..." view will be shown after this timeout
          // if the action is finished before, the timer might be cancelled
          // causing the view not to be visible at all
          const timeout = 300;
          processingViewTimeout =
              Timer(const Duration(milliseconds: timeout), () {
            notifier.send(showHoldStill());
          });
          break;
        case NfcState.success:
          notifier.send(showDone());
          notifier
              .send(const NfcHideViewEvent(delay: Duration(milliseconds: 400)));
          break;
        case NfcState.failure:
          notifier.send(showFailed());
          break;
        case NfcState.disabled:
          _log.debug('Received state: disabled');
          break;
        case NfcState.idle:
          _log.debug('Received state: idle');
          break;
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcEventNotifier.notifier);
      switch (call.method) {
        case 'show':
          notifier.send(showTapYourYubiKey());
          break;

        case 'close':
          hideOverlay();
          break;

        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
    return 0;
  }

  NfcEvent showTapYourYubiKey() {
    ref.read(nfcOverlayWidgetProperties.notifier).update(hasCloseButton: true);
    return NfcSetViewEvent(
        child: NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_tap_your_yubikey,
      icon: const NfcIconProgressBar(false),
    ));
  }

  NfcEvent showHoldStill() {
    ref.read(nfcOverlayWidgetProperties.notifier).update(hasCloseButton: false);
    return NfcSetViewEvent(
        child: NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_hold_still,
      icon: const NfcIconProgressBar(true),
    ));
  }

  NfcEvent showDone() {
    ref.read(nfcOverlayWidgetProperties.notifier).update(hasCloseButton: false);
    return NfcSetViewEvent(
        child: NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.s_done,
          icon: const NfcIconSuccess(),
        ),
        showIfHidden: false);
  }

  NfcEvent showFailed() {
    ref.read(nfcOverlayWidgetProperties.notifier).update(hasCloseButton: true);
    return NfcSetViewEvent(
        child: NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.l_nfc_failed_to_scan,
          icon: const NfcIconFailure(),
        ),
        showIfHidden: false);
  }

  void hideOverlay() {
    ref.read(nfcEventNotifier.notifier).send(const NfcHideViewEvent());
  }

  void onCancel() async {
    await _channel.invokeMethod('cancel');
  }

  Future<void> waitForHide() async {
    final completer = Completer();

    Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (ref.read(nfcOverlayWidgetProperties.select((s) => !s.visible))) {
          timer.cancel();
          completer.complete();
        }
      },
    );

    await completer.future;
  }
}
