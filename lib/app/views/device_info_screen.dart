import 'package:flutter/material.dart';

import '../models.dart';

class DeviceInfoScreen extends StatelessWidget {
  final DeviceNode device;
  const DeviceInfoScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('YubiKey: ${device.name}'),
          Text('Serial: ${device.info.serial}'),
          Text('Version: ${device.info.version}'),
        ],
      ),
    );
  }
}
