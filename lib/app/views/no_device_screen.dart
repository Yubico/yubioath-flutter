import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../desktop/state.dart';
import '../../theme.dart';
import '../../widgets/custom_icons.dart';
import '../message.dart';
import '../models.dart';
import 'device_avatar.dart';
import 'graphics.dart';
import 'message_page.dart';

class NoDeviceScreen extends ConsumerWidget {
  final DeviceNode? node;
  const NoDeviceScreen(this.node, {super.key});

  Widget _buildUsbPid(BuildContext context, WidgetRef ref, UsbPid pid) {
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows &&
          !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
        return MessagePage(
          graphic: noPermission,
          message: 'Managing this device requires elevated privileges.',
          actions: [
            OutlinedButton.icon(
              style: AppTheme.primaryOutlinedButtonStyle(context),
              label: const Text('Unlock'),
              icon: const Icon(Icons.lock_open),
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
    return node?.map(usbYubiKey: (node) {
          return _buildUsbPid(context, ref, node.pid);
        }, nfcReader: (node) {
          return MessagePage(
            graphic: DeviceAvatar(child: nfcIcon),
            message: 'Place your YubiKey on the NFC reader',
          );
        }) ??
        const MessagePage(
          graphic: DeviceAvatar(child: Icon(Icons.usb)),
          message: 'Insert your YubiKey',
        );
  }
}
