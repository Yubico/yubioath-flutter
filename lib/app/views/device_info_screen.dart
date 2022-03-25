import 'package:flutter/material.dart';

import '../models.dart';
import 'app_page.dart';

class DeviceInfoScreen extends StatelessWidget {
  final YubiKeyData device;
  const DeviceInfoScreen(this.device, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('This page intentionally left blank (for now)'),
          ],
        ),
      ),
    );
  }
}
