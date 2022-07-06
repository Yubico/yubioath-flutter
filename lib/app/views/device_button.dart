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
              radius: radius - 1,
            ),
            orElse: () => DeviceAvatar.deviceNode(
              deviceNode,
              radius: radius - 1,
            ),
          );
    } else {
      deviceWidget = DeviceAvatar(
        radius: radius - 1,
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
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconTheme(
              // Force the standard icon theme
              data: IconTheme.of(context),
              child: deviceWidget,
            ),
          ),
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
