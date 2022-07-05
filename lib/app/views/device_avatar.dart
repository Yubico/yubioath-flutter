import 'package:flutter/material.dart';

import '../../widgets/custom_icons.dart';
import '../models.dart';
import 'device_images.dart';

class DeviceAvatar extends StatelessWidget {
  final bool selected;
  final Widget child;
  final Widget? badge;
  final double? radius;
  const DeviceAvatar(
      {super.key,
      this.selected = false,
      required this.child,
      this.badge,
      this.radius});

  factory DeviceAvatar.yubiKeyData(YubiKeyData data,
          {bool selected = false, double? radius}) =>
      DeviceAvatar(
        badge: data.node is NfcReaderNode ? nfcIcon : null,
        selected: selected,
        radius: radius,
        child: getProductImage(data.info, data.name),
      );

  factory DeviceAvatar.deviceNode(DeviceNode node,
          {bool selected = false, double? radius}) =>
      node.map(
        usbYubiKey: (node) {
          final info = node.info;
          if (info != null) {
            return DeviceAvatar.yubiKeyData(
              YubiKeyData(node, node.name, info),
              selected: selected,
              radius: radius,
            );
          }
          return DeviceAvatar(
            selected: selected,
            radius: radius,
            child: const Icon(Icons.device_unknown),
          );
        },
        nfcReader: (_) => DeviceAvatar(
          selected: selected,
          radius: radius,
          child: nfcIcon,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final radius = this.radius ?? 24;
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          child: CircleAvatar(
            radius: radius - 1,
            backgroundColor: Theme.of(context).colorScheme.background,
            child: IconTheme(
              data: IconTheme.of(context).copyWith(
                size: radius,
              ),
              child: child,
            ),
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
              child: nfcIcon,
            ),
          ),
      ],
    );
  }
}
