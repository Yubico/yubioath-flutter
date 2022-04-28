import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/views/user_interaction.dart';
import '../../app/state.dart';
import '../api/impl.dart';

class FDialogApiImpl extends FDialogApi {
  final WithContext _withContext;
  UserInteractionController? _controller;
  FDialogApiImpl(this._withContext);

  @override
  Future<void> closeDialogApi() async {
    if (_controller != null) {
      _controller?.updateContent(
        description: 'Success',
        icon: const Icon(
          Icons.check_circle,
          size: 64,
        ),
      );
      Timer(const Duration(seconds: 1), () {
        _controller?.close();
        _controller = null;
      });
    }
  }

  @override
  Future<void> showDialogApi(String dialogMessage) async {
    _controller = await _withContext((context) async => promptUserInteraction(
          context,
          title: 'Tap your key',
          description: dialogMessage,
          icon: const Icon(
            Icons.wifi,
            size: 64,
          ),
          onCancel: () {
            HDialogApi _api = HDialogApi();
            _api.dialogClosed();
          },
        ));
  }
}
