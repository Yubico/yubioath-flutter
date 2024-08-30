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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import 'state.dart';
import 'views/nfc/models.dart';
import 'views/nfc/nfc_activity_overlay.dart';
import 'views/nfc/nfc_content_widget.dart';

const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

final androidDialogProvider =
    NotifierProvider<_DialogProvider, int>(_DialogProvider.new);

class _DialogProvider extends Notifier<int> {
  Timer? processingTimer;
  bool explicitAction = false;

  @override
  int build() {
    final l10n = ref.read(l10nProvider);
    ref.listen(androidNfcActivityProvider, (previous, current) {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);

      if (!explicitAction) {
        // setup properties for ad-hoc action
        ref.read(nfcViewNotifier.notifier).setDialogProperties(
              operationProcessing: l10n.s_nfc_read_key,
              operationFailure: l10n.l_nfc_read_key_failure,
              showSuccess: false,
            );
      }

      final properties = ref.read(nfcViewNotifier);

      switch (current) {
        case NfcActivity.processingStarted:
          processingTimer?.cancel();
          final timeout = explicitAction ? 300 : 200;

          processingTimer = Timer(Duration(milliseconds: timeout), () {
            if (!explicitAction) {
              // show the widget
              notifier.sendCommand(showNfcView(NfcContentWidget(
                title: properties.operationProcessing,
                subtitle: '',
                inProgress: true,
              )));
            } else {
              // the processing view will only be shown if the timer is still active
              notifier.sendCommand(updateNfcView(NfcContentWidget(
                title: properties.operationProcessing,
                subtitle: l10n.s_nfc_hold_key,
                inProgress: true,
              )));
            }
          });
          break;
        case NfcActivity.processingFinished:
          explicitAction = false; // next action might not be explicit
          processingTimer?.cancel();
          if (properties.showSuccess ?? false) {
            notifier.sendCommand(
                updateNfcView(NfcActivityClosingCountdownWidgetView(
              closeInSec: 5,
              child: NfcContentWidget(
                title: properties.operationSuccess,
                subtitle: l10n.s_nfc_remove_key,
                inProgress: false,
              ),
            )));
          } else {
            // directly hide
            notifier.sendCommand(hideNfcView);
          }
          break;
        case NfcActivity.processingInterrupted:
          explicitAction = false; // next action might not be explicit
          notifier.sendCommand(updateNfcView(NfcContentWidget(
            title: properties.operationFailure,
            inProgress: false,
          )));
          break;
        case NfcActivity.notActive:
          debugPrint('Received not handled notActive');
          break;
        case NfcActivity.ready:
          debugPrint('Received not handled ready');
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);
      final properties = ref.read(nfcViewNotifier);
      switch (call.method) {
        case 'show':
          explicitAction = true;
          notifier.sendCommand(showNfcView(NfcContentWidget(
            title: properties.operationName ?? '[OPERATION NAME MISSING]',
            subtitle: 'Scan your YubiKey',
            inProgress: false,
          )));
          break;

        case 'close':
          notifier.sendCommand(hideNfcView);
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

  void cancelDialog() async {
    debugPrint('Cancelled dialog');
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

class MethodChannelHelper {
  final ProviderRef _ref;
  final MethodChannel _channel;

  const MethodChannelHelper(this._ref, this._channel);

  Future<dynamic> invoke(String method,
      {String? operationName,
      String? operationSuccess,
      String? operationProcessing,
      String? operationFailure,
      bool? showSuccess,
      Map<String, dynamic> arguments = const {}}) async {
    final notifier = _ref.read(nfcViewNotifier.notifier);
    notifier.setDialogProperties(
        operationName: operationName,
        operationProcessing: operationProcessing,
        operationSuccess: operationSuccess,
        operationFailure: operationFailure,
        showSuccess: showSuccess);

    final result = await _channel.invokeMethod(method, arguments);
    await _ref.read(androidDialogProvider.notifier).waitForDialogClosed();
    return result;
  }
}
