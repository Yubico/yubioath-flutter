import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../desktop/state.dart';
import '../message.dart';
import '../models.dart';
import 'device_avatar.dart';
import 'graphics.dart';
import 'message_page.dart';

class DeviceErrorScreen extends ConsumerWidget {
  final DeviceNode node;
  final Object? error;
  const DeviceErrorScreen(this.node, {this.error, super.key});

  Widget _buildUsbPid(BuildContext context, WidgetRef ref, UsbPid pid) {
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows &&
          !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
        return MessagePage(
          graphic: noPermission,
          message: 'Managing this device requires elevated privileges.',
          actions: [
            ElevatedButton.icon(
              label: const Text('Unlock'),
              icon: const Icon(Icons.lock_open),
              onPressed: () async {
                final closeMessage = showMessage(
                    context, 'Elevating permissions...',
                    duration: const Duration(seconds: 30));
                try {
                  if (await ref.read(rpcProvider).elevate()) {
                    ref.refresh(rpcProvider);
                  } else {
                    showMessage(context, 'Permission denied');
                  }
                } finally {
                  closeMessage();
                }
              },
            ),
          ],
        );
      }
    }
    return const MessagePage(
      graphic: DeviceAvatar(child: Icon(Icons.usb_off)),
      message: 'This YubiKey cannot be accessed',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return node.map(
      usbYubiKey: (node) => _buildUsbPid(context, ref, node.pid),
      nfcReader: (node) {
        final String message;
        switch (error) {
          case 'unknown-device':
            message = 'Unrecognized device';
            break;
          default:
            message = 'Place your YubiKey on the NFC reader';
        }
        return MessagePage(message: message);
      },
    );
  }
}
