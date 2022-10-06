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

  Widget? _getIcon(String? icon) {
    switch (icon) {
      case 'nfc':
        return nfcIcon;
      case 'success':
        return const Icon(Icons.check_circle);
      case 'error':
        return const Icon(Icons.error);
      default:
        return null;
    }
  }

  Future<void> _updateDialogState(
      String? title, String? description, String? iconName) async {
    final icon = _getIcon(iconName);
    await _withContext((context) async {
      _controller?.updateContent(
        title: title,
        description: description,
        icon: icon != null
            ? IconTheme(
                data: IconTheme.of(context).copyWith(size: 64),
                child: icon,
              )
            : null,
      );
    });
  }

  Future<void> _showDialog(
      String title, String description, String? iconName) async {
    final icon = _getIcon(iconName);
    _controller = await _withContext((context) async => promptUserInteraction(
          context,
          title: title,
          description: description,
          icon: icon != null
              ? IconTheme(
                  data: IconTheme.of(context).copyWith(size: 64),
                  child: icon,
                )
              : null,
          onCancel: () {
            _channel.invokeMethod('cancel');
          },
        ));
  }
}
