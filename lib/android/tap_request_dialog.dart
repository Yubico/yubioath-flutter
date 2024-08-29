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
import 'package:material_symbols_icons/symbols.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../widgets/pulsing.dart';
import 'state.dart';
import 'views/nfc/nfc_activity_overlay.dart';

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
      final notifier = ref.read(nfcActivityCommandNotifier.notifier);

      if (!explicitAction) {
        // setup properties for ad-hoc action
        ref.read(nfcActivityWidgetNotifier.notifier).setDialogProperties(
              operationProcessing: l10n.s_nfc_read_key,
              operationFailure: l10n.l_nfc_read_key_failure,
              showSuccess: false,
            );
      }

      final properties = ref.read(nfcActivityWidgetNotifier);

      debugPrint('XXX now it is: $current');
      switch (current) {
        case NfcActivity.processingStarted:
          processingTimer?.cancel();

          debugPrint('XXX explicit action: $explicitAction');
          final timeout = explicitAction ? 300 : 200;

          processingTimer = Timer(Duration(milliseconds: timeout), () {
            if (!explicitAction) {
              // show the widget
              notifier.update(NfcActivityWidgetCommand(
                  action: NfcActivityWidgetActionShowWidget(
                      child: _NfcActivityWidgetView(
                title: properties.operationProcessing,
                subtitle: '',
                inProgress: true,
              ))));
            } else {
              // the processing view will only be shown if the timer is still active
              notifier.update(NfcActivityWidgetCommand(
                  action: NfcActivityWidgetActionSetWidgetData(
                      child: _NfcActivityWidgetView(
                title: properties.operationProcessing,
                subtitle: l10n.s_nfc_hold_key,
                inProgress: true,
              ))));
            }
          });
          break;
        case NfcActivity.processingFinished:
          explicitAction = false; // next action might not be explicit
          processingTimer?.cancel();
          if (properties.showSuccess ?? false) {
            notifier.update(NfcActivityWidgetCommand(
                action: NfcActivityWidgetActionSetWidgetData(
                    child: NfcActivityClosingCountdownWidgetView(
              closeInSec: 5,
              child: _NfcActivityWidgetView(
                title: properties.operationSuccess,
                subtitle: l10n.s_nfc_remove_key,
                inProgress: false,
              ),
            ))));
          } else {
            // directly hide
            notifier.update(NfcActivityWidgetCommand(
                action: const NfcActivityWidgetActionHideWidget(timeoutMs: 0)));
          }
          break;
        case NfcActivity.processingInterrupted:
          explicitAction = false; // next action might not be explicit
          notifier.update(NfcActivityWidgetCommand(
              action: NfcActivityWidgetActionSetWidgetData(
                  child: _NfcActivityWidgetView(
            title: properties.operationFailure,
            inProgress: false,
          ))));
          break;
        case NfcActivity.notActive:
          debugPrint('Received not handled notActive');
          break;
        case NfcActivity.ready:
          debugPrint('Received not handled ready');
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcActivityCommandNotifier.notifier);
      final properties = ref.read(nfcActivityWidgetNotifier);
      switch (call.method) {
        case 'show':
          explicitAction = true;
          notifier.update(NfcActivityWidgetCommand(
              action: NfcActivityWidgetActionShowWidget(
                  child: _NfcActivityWidgetView(
            title: l10n.s_nfc_tap_for(
                properties.operationName ?? '[OPERATION NAME MISSING]'),
            subtitle: '',
            inProgress: false,
          ))));
          break;

        case 'close':
          notifier.update(NfcActivityWidgetCommand(
              action: const NfcActivityWidgetActionHideWidget(timeoutMs: 0)));
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
        if (!ref.read(nfcActivityWidgetNotifier.select((s) => s.isShowing))) {
          timer.cancel();
          completer.complete();
        }
      },
    );

    await completer.future;
  }
}

class _NfcActivityWidgetView extends StatelessWidget {
  final bool inProgress;
  final String? title;
  final String? subtitle;

  const _NfcActivityWidgetView(
      {required this.title, this.subtitle, this.inProgress = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(title ?? 'Missing title',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (subtitle != null)
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 32),
          inProgress
              ? const Pulsing(child: Icon(Symbols.contactless, size: 64))
              : const Icon(Symbols.contactless, size: 64),
          const SizedBox(height: 24)
        ],
      ),
    );
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
    final notifier = _ref.read(nfcActivityWidgetNotifier.notifier);
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

class MethodChannelNotifier extends Notifier<void> {
  final MethodChannel _channel;

  MethodChannelNotifier(this._channel);

  @override
  void build() {}

  Future<dynamic> invoke(String name,
      [Map<String, dynamic> params = const {}]) async {
    final notifier = ref.read(nfcActivityWidgetNotifier.notifier);
    notifier.setDialogProperties(
        operationName: params['operationName'],
        operationProcessing: params['operationProcessing'],
        operationSuccess: params['operationSuccess'],
        operationFailure: params['operationFailure'],
        showSuccess: params['showSuccess']);

    final result = await _channel.invokeMethod(name, params['callArgs']);
    await ref.read(androidDialogProvider.notifier).waitForDialogClosed();
    return result;
  }
}
