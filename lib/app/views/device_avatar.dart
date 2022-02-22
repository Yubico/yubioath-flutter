import 'package:flutter/material.dart';

import '../models.dart';
import 'device_images.dart';

class DeviceAvatar extends StatelessWidget {
  final bool selected;
  final Widget child;
  final IconData? badge;
  const DeviceAvatar._(
      {Key? key, this.selected = false, required this.child, this.badge})
      : super(key: key);

  factory DeviceAvatar.yubiKeyData(YubiKeyData data, {bool selected = false}) =>
      DeviceAvatar._(
        child: getProductImage(data.info, data.name),
        badge: data.node is NfcReaderNode ? Icons.wifi : null,
        selected: selected,
      );

  factory DeviceAvatar.deviceNode(DeviceNode node, {bool selected = false}) =>
      node.map(
        usbYubiKey: (node) => DeviceAvatar.yubiKeyData(
          YubiKeyData(node, node.name, node.info),
          selected: selected,
        ),
        nfcReader: (_) => DeviceAvatar._(
          child: const Icon(Icons.wifi),
          selected: selected,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: selected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.background,
            child: child,
          ),
        ),
        if (badge != null)
          CircleAvatar(
            radius: 8,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(
              badge!,
              size: 12,
            ),
          ),
      ],
    );
  }
}
