import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../about_page.dart';
import '../models.dart';
import '../state.dart';

class DevicePickerDialog extends ConsumerWidget {
  const DevicePickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final devices = ref.watch(attachedDevicesProvider);

    Widget _buildDeviceInfo(DeviceNode device) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Text('YK')),
                const SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name),
                    Text(
                        'Version: ${device.info.version} Serial: ${device.info.serial}'),
                  ],
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      );
    }

    return SimpleDialog(
      //title: Text(device?.name ?? 'No YubiKey'),
      children: [
        if (device != null) _buildDeviceInfo(device),
        ...devices.where((e) => e != device).map((e) => TextButton(
              child: Text(e.name),
              onPressed: () {
                ref.read(currentDeviceProvider.notifier).setCurrentDevice(e);
                Navigator.of(context).pop();
              },
            )),
        const Divider(),
        TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
            child: const Text('About Yubico Authenticator...'))
      ],
    );
  }
}
