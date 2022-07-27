import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../widgets/custom_icons.dart';
import '../api/impl.dart';

class FDialogApiImpl extends FDialogApi {
  final WithContext _withContext;
  UserInteractionController? _controller;

  FDialogApiImpl(this._withContext);

  @override
  void closeDialog() {
    _controller?.close();
    _controller = null;
  }

  @override
  Future<void> updateDialogState(
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

  @override
  Future<void> showDialog(String dialogMessage) async {
    _controller = await _withContext((context) async => promptUserInteraction(
          context,
          title: 'Tap your key',
          description: dialogMessage,
          icon: IconTheme(
            data: IconTheme.of(context).copyWith(size: 64),
            child: nfcIcon,
          ),
          onCancel: () {
            HDialogApi api = HDialogApi();
            api.dialogClosed();
          },
        ));
  }
}
