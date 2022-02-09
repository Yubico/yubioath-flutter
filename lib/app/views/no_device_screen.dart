import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

class NoDeviceScreen extends ConsumerWidget {
  const NoDeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final isNfc = device is NfcReaderNode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isNfc
            ? const [
                DeviceAvatar(child: Icon(Icons.wifi)),
                Text('Place your YubiKey on the NFC reader'),
              ]
            : const [
                DeviceAvatar(child: Icon(Icons.usb)),
                Text('Insert your YubiKey'),
              ],
      ),
    );
  }
}
