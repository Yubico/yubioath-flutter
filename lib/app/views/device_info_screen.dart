import 'package:flutter/material.dart';

import '../models.dart';
import 'app_page.dart';

class DeviceInfoScreen extends StatelessWidget {
  final YubiKeyData device;
  const DeviceInfoScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: const Text('Coming soon!'),
      centered: true,
      child: const Text('This page intentionally left blank (for now)'),
    );
  }
}
