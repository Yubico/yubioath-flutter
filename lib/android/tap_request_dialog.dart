/*
 * Copyright (C) 2022 Yubico.
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
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/android/state.dart';
import 'package:yubico_authenticator/android/views/nfc/nfc_activity_background.dart';
import 'package:yubico_authenticator/android/views/nfc/nfc_activity_widget.dart';

import '../app/state.dart';
import '../app/views/user_interaction.dart';
import '../widgets/custom_icons.dart';

const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

final androidDialogProvider = Provider<_DialogProvider>(
  (ref) {
    return _DialogProvider(ref.watch(withContextProvider));
  },
);

class _DialogProvider {
  final WithContext _withContext;
  UserInteractionController? _controller;

  _DialogProvider(this._withContext) {
    _channel.setMethodCallHandler((call) async {
      final args = jsonDecode(call.arguments);
      switch (call.method) {
        case 'close':
          _closeDialog();
          break;
        case 'show':
          await _showDialog(args['title'], args['description'], args['icon']);
          break;
        case 'state':
          await _updateDialogState(
              args['title'], args['description'], args['icon']);
          break;
        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
  }

  void _closeDialog() {
    _controller?.close();
    _controller = null;
  }

  Future<void> _updateDialogState(
      String? title, String? description, String? iconName) async {
    await _withContext((context) async {
      _controller?.updateContent(
        title: title,
        description: description,
        icon: _createIcon(context),
      );
    });
  }

  Future<void> _showDialog(
      String title, String description, String? iconName) async {
    _controller = await _withContext((context) async {
      return promptUserInteraction(
        context,
        title: title,
        description: description,
        icon: _createIcon(context),
        onCancel: () {
          _channel.invokeMethod('cancel');
        },
      );
    });
  }

  NfcActivityWidget _createIcon(BuildContext context) {
    final pulseColor = Theme.of(context).primaryColor;

    return NfcActivityWidget(
      width: 64,
      height: 64,
      iconFn: (NfcActivity nfcActivityState) {
        return nfcIcon;
      },
      backgroundFn: (NfcActivity nfcActivityState) =>
          switch (nfcActivityState) {
        NfcActivity.notActive => const SizedBox.shrink(),
        NfcActivity.ready => NfcActivityBackground(
            foregroundColor: pulseColor,
            opacity: 0.2,
          ),
        NfcActivity.tagPresent => NfcActivityBackground(
            foregroundColor: pulseColor,
            opacity: 0.5,
          ),
        NfcActivity.processingStarted => const NfcActivityBackground(
            foregroundColor: Colors.blueGrey,
            opacity: 0.8,
          ),
        NfcActivity.processingFinished => NfcActivityBackground(
            foregroundColor: pulseColor,
            opacity: 0.5,
          ),
        NfcActivity _ => const NfcActivityBackground()
      },
    );
  }
}
