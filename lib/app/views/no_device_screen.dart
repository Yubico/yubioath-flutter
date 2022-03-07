import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import 'device_avatar.dart';

class NoDeviceScreen extends ConsumerWidget {
  final DeviceNode? node;
  const NoDeviceScreen(this.node, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final device = ref.watch(currentDeviceProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: node?.when(usbYubiKey: (path, name, pid, info) {
              return const [
                // TODO: Handle different cases based on PID and platform
                DeviceAvatar(child: Icon(Icons.usb_off)),
                Text('This YubiKey cannot be accessed'),
              ];
            }, nfcReader: (path, name) {
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
