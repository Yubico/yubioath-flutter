import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';
import 'device_avatar.dart';
import 'device_picker_dialog.dart';

class DeviceButton extends ConsumerWidget {
  const DeviceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceNode = ref.watch(currentDeviceProvider);
    final deviceData = ref.watch(currentDeviceDataProvider);
    Widget deviceWidget;
    if (deviceNode != null) {
      if (deviceData != null) {
        deviceWidget = DeviceAvatar.yubiKeyData(
          deviceData,
          selected: true,
        );
      } else {
        deviceWidget = DeviceAvatar.deviceNode(
          deviceNode,
          selected: true,
        );
      }
    } else {
      deviceWidget = const DeviceAvatar(
        child: Icon(Icons.more_horiz),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: OverflowBox(
          maxHeight: 44,
          maxWidth: 44,
          child: deviceWidget,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const DevicePickerDialog(),
          );
        },
      ),
    );
  }
}
