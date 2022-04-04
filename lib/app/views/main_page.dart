import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'no_device_screen.dart';
import 'device_info_screen.dart';
import '../models.dart';
import '../state.dart';
import '../../fido/views/fido_screen.dart';
import '../../oath/views/oath_screen.dart';
import '../../management/views/management_screen.dart';

class MainPage extends ConsumerWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceData = ref.watch(currentDeviceDataProvider);
    if (deviceData == null) {
      final node = ref.watch(currentDeviceProvider);
      return NoDeviceScreen(node);
    }
    final app = ref.watch(currentAppProvider);
    if (app.getAvailability(deviceData) != Availability.enabled) {
      return const Center(
        child: Text('This application is disabled'),
      );
    }

    switch (app) {
      case Application.oath:
        return OathScreen(deviceData.node.path);
      case Application.management:
        return ManagementScreen(deviceData);
      case Application.fido:
        return FidoScreen(deviceData);
      default:
        return DeviceInfoScreen(deviceData);
    }
  }
}
