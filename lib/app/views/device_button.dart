import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../message.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'device_picker_dialog.dart';

class DeviceButton extends ConsumerWidget {
  final double radius;
  const DeviceButton({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceNode = ref.watch(currentDeviceProvider);
    Widget deviceWidget;
    if (deviceNode != null) {
      deviceWidget = ref.watch(currentDeviceDataProvider).maybeWhen(
            data: (data) => DeviceAvatar.yubiKeyData(
              data,
              selected: true,
              radius: radius,
            ),
            orElse: () => DeviceAvatar.deviceNode(
              deviceNode,
              selected: true,
              radius: radius,
            ),
          );
    } else {
      deviceWidget = DeviceAvatar(
        radius: radius,
        selected: true,
        child: const Icon(Icons.usb),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        tooltip: 'Select YubiKey or device',
        icon: OverflowBox(
          maxHeight: 44,
          maxWidth: 44,
          child: deviceWidget,
        ),
        onPressed: () {
          showBlurDialog(
            context: context,
            builder: (context) => const DevicePickerDialog(),
            routeSettings: const RouteSettings(name: 'device_picker'),
          );
        },
      ),
    );
  }
}
