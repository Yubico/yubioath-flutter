import 'package:flutter/material.dart';

import '../models.dart';
import 'device_images.dart';

class DeviceAvatar extends StatelessWidget {
  final DeviceNode device;
  final bool selected;

  const DeviceAvatar(this.device, {this.selected = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: CircleAvatar(
        child: getProductImage(device),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      radius: 22,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.secondary
          : Colors.transparent,
    );
  }
}
