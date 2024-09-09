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

import '../app/logging.dart';
import '../app/state.dart';
import 'state.dart';
import 'views/nfc/models.dart';
import 'views/nfc/nfc_activity_overlay.dart';
import 'views/nfc/nfc_content_widget.dart';
import 'views/nfc/nfc_failure_icon.dart';
import 'views/nfc/nfc_progress_bar.dart';
import 'views/nfc/nfc_success_icon.dart';

final _log = Logger('android.tap_request_dialog');
const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

final androidDialogProvider =
    NotifierProvider<_DialogProvider, int>(_DialogProvider.new);

class _DialogProvider extends Notifier<int> {
  Timer? processingViewTimeout;
  late final l10n = ref.read(l10nProvider);

  @override
  int build() {
    ref.listen(androidNfcActivityProvider, (previous, current) {
      processingViewTimeout?.cancel();
      final notifier = ref.read(nfcEventNotifier.notifier);

      switch (current) {
        case NfcActivity.processingStarted:
          // the "Hold still..." view will be shown after this timeout
          // if the action is finished before, the timer might be cancelled
          // causing the view not to be visible at all
          const timeout = 300;
          processingViewTimeout =
              Timer(const Duration(milliseconds: timeout), () {
            notifier.send(showHoldStill());
          });
          break;
        case NfcActivity.processingFinished:
          notifier.send(showDone());
          notifier
              .send(const NfcHideViewEvent(delay: Duration(milliseconds: 400)));
          break;
        case NfcActivity.processingInterrupted:
          notifier.send(showFailed());
          break;
        case NfcActivity.notActive:
          _log.debug('Received not handled notActive');
          break;
        case NfcActivity.ready:
          _log.debug('Received not handled ready');
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcEventNotifier.notifier);
      switch (call.method) {
        case 'show':
          notifier.send(showTapYourYubiKey());
          break;

        case 'close':
          closeDialog();
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
    ref
        .read(nfcActivityWidgetPropertiesNotifier.notifier)
        .update(hasCloseButton: true);
    return NfcSetViewEvent(
        child: NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_tap_your_yubikey,
      icon: const NfcIconProgressBar(false),
    ));
  }

  NfcEvent showHoldStill() {
    ref
        .read(nfcActivityWidgetPropertiesNotifier.notifier)
        .update(hasCloseButton: false);
    return NfcSetViewEvent(
        child: NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_hold_still,
      icon: const NfcIconProgressBar(true),
    ));
  }

  NfcEvent showDone() {
    ref
        .read(nfcActivityWidgetPropertiesNotifier.notifier)
        .update(hasCloseButton: false);
    return NfcSetViewEvent(
        child: NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.s_done,
          icon: const NfcIconSuccess(),
        ),
        showIfHidden: false);
  }

  NfcEvent showFailed() {
    ref
        .read(nfcActivityWidgetPropertiesNotifier.notifier)
        .update(hasCloseButton: true);
    return NfcSetViewEvent(
        child: NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.l_nfc_failed_to_scan,
          icon: const NfcIconFailure(),
        ),
        showIfHidden: false);
  }

  void closeDialog() {
    ref.read(nfcEventNotifier.notifier).send(const NfcHideViewEvent());
  }

  void cancelDialog() async {
    await _channel.invokeMethod('cancel');
  }

  Future<void> waitForDialogClosed() async {
    final completer = Completer();

    Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (ref.read(
            nfcActivityWidgetPropertiesNotifier.select((s) => !s.visible))) {
          timer.cancel();
          completer.complete();
        }
      },
    );

    await completer.future;
  }
}
