import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../desktop/state.dart';
import '../models.dart';
import 'app_page.dart';
import 'device_avatar.dart';

class NoDeviceScreen extends ConsumerWidget {
  final DeviceNode? node;
  const NoDeviceScreen(this.node, {Key? key}) : super(key: key);

  String _getErrorMessage(WidgetRef ref, UsbPid pid) {
    // TODO: Handle more cases
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows) {
        if (!ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
          return 'WebAuthn management requires elevated privileges.\nRestart this app as administrator.';
        }
      }
    }
    return 'This YubiKey cannot be accessed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: node?.map(usbYubiKey: (node) {
                return [
                  const DeviceAvatar(child: Icon(Icons.usb_off)),
                  Text(
                    _getErrorMessage(ref, node.pid),
                    textAlign: TextAlign.center,
                  ),
                ];
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
      ),
    );
  }
}
