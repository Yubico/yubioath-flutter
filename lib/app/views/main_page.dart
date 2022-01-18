import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_avatar.dart';
import 'main_actions_dialog.dart';
import 'main_drawer.dart';
import 'no_device_screen.dart';
import 'device_info_screen.dart';
import '../models.dart';
import '../state.dart';
import '../../oath/views/oath_screen.dart';

class MainPage extends ConsumerWidget {
  const MainPage({Key? key}) : super(key: key);

  Widget _buildSubPage(SubPage subPage, YubiKeyData? device) {
    if (device == null) {
      return const NoDeviceScreen();
    }
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
    final deviceData = ref.watch(currentDeviceDataProvider);
    final subPage = ref.watch(subPageProvider);

    return Scaffold(
      appBar: AppBar(
        /*
        The following can be used to customize the appearence of the app bar,
        should we wish to do so. More advanced changes may require using a
        custom Widget instead.

        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          side: BorderSide(
              width: 8, color: Theme.of(context).scaffoldBackgroundColor),
        ),
        */
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchProvider.notifier).setFilter(value);
          },
        ),
        actions: [
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: deviceData == null
                  ? SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        Icons.usb_off,
                        color: Theme.of(context).colorScheme.background,
                      ),
                    )
                  : DeviceAvatar(
                      deviceData.node,
                      deviceData.name,
                      deviceData.info,
                      selected: true,
                    ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const MainActionsDialog(),
              );
            },
          ),
        ],
      ),
      drawer: const MainPageDrawer(),
      body: _buildSubPage(subPage, deviceData),
    );
  }
}
