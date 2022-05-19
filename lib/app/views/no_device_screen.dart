import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../desktop/state.dart';
import '../message.dart';
import '../models.dart';
import 'app_page.dart';
import 'device_avatar.dart';
import 'graphics.dart';

class NoDeviceScreen extends ConsumerWidget {
  final DeviceNode? node;
  const NoDeviceScreen(this.node, {super.key});

  List<Widget> _buildUsbPid(BuildContext context, WidgetRef ref, UsbPid pid) {
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows &&
          !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
        return [
          noPermission,
          const Text('WebAuthn management requires elevated privileges.'),
          OutlinedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock'),
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
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList();
      }
    }
    return [
      const DeviceAvatar(child: Icon(Icons.usb_off)),
      const Text(
        'This YubiKey cannot be accessed',
        textAlign: TextAlign.center,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      centered: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: node?.map(usbYubiKey: (node) {
              return _buildUsbPid(context, ref, node.pid);
            }, nfcReader: (node) {
              return const [
                DeviceAvatar(child: Icon(Icons.wifi)),
                Text('Place your YubiKey on the NFC reader'),
              ];
            }) ??
            const [
              DeviceAvatar(child: Icon(Icons.usb)),
              Text('Insert your YubiKey'),
            ],
      ),
    );
  }
}
