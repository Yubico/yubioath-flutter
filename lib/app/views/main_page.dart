import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_picker_dialog.dart';
import 'main_drawer.dart';
import 'no_device_screen.dart';
import 'device_info_screen.dart';
import '../models.dart';
import '../state.dart';
import '../../oath/views/oath_screen.dart';

class MainPage extends ConsumerWidget {
  const MainPage({Key? key}) : super(key: key);

  Widget _buildSubPage(SubPage subPage, DeviceNode device) {
    // TODO: If page not supported by device, do something?
    switch (subPage) {
      case SubPage.authenticator:
        return OathScreen(device);
      case SubPage.yubikey:
        return DeviceInfoScreen(device);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDevice = ref.watch(currentDeviceProvider);
    final subPage = ref.watch(subPageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yubico Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DevicePickerDialog(),
              );
            },
          )
        ],
      ),
      drawer: const MainPageDrawer(),
      body: currentDevice == null
          ? const NoDeviceScreen()
          : _buildSubPage(subPage, currentDevice),
    );
  }
}
