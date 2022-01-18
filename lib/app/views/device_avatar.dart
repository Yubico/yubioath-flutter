import 'package:flutter/material.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../models.dart';
import 'device_images.dart';

/*
TODO: This class should be refactored once we settle more on the final design.
We may want to have two separate implementations depending on if it's an NFC reader or a USB YubiKey.
*/
class DeviceAvatar extends StatelessWidget {
  final DeviceNode node;
  final String name;
  final DeviceInfo? info;
  final bool selected;

  const DeviceAvatar(this.node, this.name, this.info,
      {this.selected = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: CircleAvatar(
        child:
            info != null ? getProductImage(info!, name) : const Icon(Icons.nfc),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      radius: 22,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.secondary
          : Colors.transparent,
    );
  }
}
