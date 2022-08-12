import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../../widgets/custom_icons.dart';
import '../models.dart';
import '../state.dart';
import 'device_images.dart';

class DeviceAvatar extends StatelessWidget {
  final Widget child;
  final Widget? badge;
  final double? radius;
  const DeviceAvatar({super.key, required this.child, this.badge, this.radius});

  factory DeviceAvatar.yubiKeyData(YubiKeyData data, {double? radius}) =>
      DeviceAvatar(
        badge: isDesktop && data.node is NfcReaderNode ? nfcIcon : null,
        radius: radius,
        child: getProductImage(data.info, data.name),
      );

  factory DeviceAvatar.deviceNode(DeviceNode node, {double? radius}) =>
      node.map(
        usbYubiKey: (node) {
          final info = node.info;
          if (info != null) {
            return DeviceAvatar.yubiKeyData(
              YubiKeyData(node, node.name, info),
              radius: radius,
            );
          }
          return DeviceAvatar(
            radius: radius,
            child: const Icon(Icons.device_unknown),
          );
        },
        nfcReader: (_) => DeviceAvatar(
          radius: radius,
          child: nfcIcon,
        ),
      );

  factory DeviceAvatar.currentDevice(WidgetRef ref, {double? radius}) {
    final deviceNode = ref.watch(currentDeviceProvider);
    if (deviceNode != null) {
      return ref.watch(currentDeviceDataProvider).maybeWhen(
            data: (data) => DeviceAvatar.yubiKeyData(
              data,
              radius: radius,
            ),
            orElse: () => DeviceAvatar.deviceNode(
              deviceNode,
              radius: radius,
            ),
          );
    } else {
      return DeviceAvatar(
        radius: radius,
        child: const Icon(Icons.usb),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = this.radius ?? 20;
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.background,
          child: IconTheme(
            data: IconTheme.of(context).copyWith(
              size: radius,
            ),
            child: child,
          ),
        ),
        if (badge != null)
          CircleAvatar(
            radius: radius / 3,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconTheme(
              data: IconTheme.of(context).copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                size: radius * 0.5,
              ),
              child: badge!,
            ),
          ),
      ],
    );
  }
}
