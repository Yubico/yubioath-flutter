import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desktop/models.dart';
import '../../desktop/state.dart';
import '../../theme.dart';
import '../message.dart';
import 'graphics.dart';
import 'message_page.dart';

class AppFailurePage extends ConsumerWidget {
  final Widget? title;
  final Object cause;
  const AppFailurePage({this.title, required this.cause, super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = cause;

    Widget? graphic = const Icon(Icons.error);
    String? header = 'An error has occured';
    String? message = reason.toString();
    List<Widget> actions = [];

    if (reason is RpcError) {
      if (reason.status == 'connection-error') {
        switch (reason.body['connection']) {
          case 'ccid':
            header = 'Failed to open smart card connection';
            if (Platform.isMacOS) {
              message = 'Try to remove and re-insert your YubiKey.';
            } else if (Platform.isLinux) {
              message = 'Make sure pcscd is running.';
            } else {
              message = 'Make sure your smart card service is functioning.';
            }
            break;
          case 'fido':
            if (Platform.isWindows &&
                !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
              graphic = noPermission;
              header = null;
              message = 'WebAuthn management requires elevated privileges.';
              actions = [
                OutlinedButton.icon(
                    label: const Text('Unlock'),
                    icon: const Icon(Icons.lock_open),
                    style: AppTheme.primaryOutlinedButtonStyle(context),
                    onPressed: () async {
                      final controller = showMessage(
                          context, 'Elevating permissions...',
                          duration: const Duration(seconds: 30));
                      try {
                        if (await ref.read(rpcProvider).elevate()) {
                          ref.refresh(rpcProvider);
                        } else {
                          showMessage(context, 'Permission denied');
                        }
                      } finally {
                        controller.close();
                      }
                    }),
              ];
            }
            break;
          default:
            header = 'Failed to open connection';
            message = 'Try to remove and re-insert your YubiKey.';
        }
      }
    }

    return MessagePage(
      title: title,
      graphic: graphic,
      header: header,
      message: message,
      actions: actions,
    );
  }
}
