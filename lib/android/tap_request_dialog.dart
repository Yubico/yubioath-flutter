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
import '../app/message.dart';
import '../app/state.dart';
import 'state.dart';
import 'views/nfc/models.dart';
import 'views/nfc/nfc_activity_overlay.dart';
import 'views/nfc/nfc_auto_close_widget.dart';
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
  bool explicitAction = false;

  late final l10n = ref.read(l10nProvider);

  @override
  int build() {
    final l10n = ref.read(l10nProvider);
    final viewNotifier = ref.read(nfcViewNotifier.notifier);

    ref.listen(androidNfcActivityProvider, (previous, current) {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);

      if (!explicitAction) {
        // setup properties for ad-hoc action
        viewNotifier.setDialogProperties(
            operationSuccess: l10n.s_nfc_scan_success,
            operationFailure: l10n.l_nfc_read_key_failure,
            showSuccess: true,
            showCloseButton: false);
      }

      final properties = ref.read(nfcViewNotifier);

      switch (current) {
        case NfcActivity.processingStarted:
          final timeout = explicitAction ? 300 : 500;
          processingViewTimeout?.cancel();
          processingViewTimeout = Timer(Duration(milliseconds: timeout), () {
            notifier.sendCommand(showAccessingKeyView());
          });
          break;
        case NfcActivity.processingFinished:
          processingViewTimeout?.cancel();
          final showSuccess = properties.showSuccess ?? false;
          allowMessages = !showSuccess;
          if (showSuccess) {
            notifier.sendCommand(autoClose(
                title: properties.operationSuccess,
                subtitle: explicitAction ? l10n.s_nfc_remove_key : null,
                icon: const NfcIconSuccess(),
                showIfHidden: false));
            // hide
          }
          notifier.sendCommand(hideNfcView(Duration(
              milliseconds: !showSuccess
                  ? 0
                  : explicitAction
                      ? 5000
                      : 400)));

          explicitAction = false; // next action might not be explicit
          break;
        case NfcActivity.processingInterrupted:
          processingViewTimeout?.cancel();
          viewNotifier.setDialogProperties(showCloseButton: true);
          notifier.sendCommand(setNfcView(NfcContentWidget(
            title: properties.operationFailure,
            subtitle: l10n.s_nfc_scan_again,
            icon: const NfcIconFailure(),
          )));
          break;
        case NfcActivity.notActive:
          _log.debug('Received not handled notActive');
          break;
        case NfcActivity.ready:
          _log.debug('Received not handled ready');
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);
      switch (call.method) {
        case 'show':
          explicitAction = true;
          notifier.sendCommand(showScanKeyView());
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

  NfcEventCommand showScanKeyView() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: true);
    return setNfcView(NfcContentWidget(
      subtitle: l10n.s_nfc_scan_yubikey,
      icon: const NfcIconProgressBar(false),
    ));
  }

  NfcEventCommand showAccessingKeyView() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: false);
    return setNfcView(NfcContentWidget(
      title: l10n.s_nfc_accessing_yubikey,
      icon: const NfcIconProgressBar(true),
    ));
  }

  void closeDialog() {
    ref.read(nfcEventCommandNotifier.notifier).sendCommand(hideNfcView());
  }

  void cancelDialog() async {
    explicitAction = false;
    await _channel.invokeMethod('cancel');
  }

  Future<void> waitForDialogClosed() async {
    final completer = Completer();

    Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (!ref.read(nfcViewNotifier.select((s) => s.isShowing))) {
          timer.cancel();
          completer.complete();
        }
      },
    );

    await completer.future;
  }
}
