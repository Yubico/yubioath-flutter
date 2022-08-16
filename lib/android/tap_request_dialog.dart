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
          await _showDialog(args['message']);
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
      String? title, String? description, String? icon) async {
    final iconResource = icon == 'check_circle'
        ? Icons.check_circle
        : icon == 'error'
            ? Icons.error
            : null;
    final dialogIcon = Icon(
      iconResource,
      size: 64,
    );
    _controller?.updateContent(
      title: title,
      description: description,
      icon: dialogIcon,
    );
  }

  Future<void> _showDialog(String dialogMessage) async {
    _controller = await _withContext((context) async => promptUserInteraction(
          context,
          title: 'Tap your key',
          description: dialogMessage,
          icon: IconTheme(
            data: IconTheme.of(context).copyWith(size: 64),
            child: nfcIcon,
          ),
          onCancel: () {
            _channel.invokeMethod('cancel');
          },
        ));
  }
}
