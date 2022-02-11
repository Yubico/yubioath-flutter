import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final deviceNode = ref.watch(currentDeviceProvider);
    final deviceData = ref.watch(currentDeviceDataProvider);
    final subPage = ref.watch(subPageProvider);

    Widget deviceWidget;
    if (deviceNode != null) {
      if (deviceData != null) {
        deviceWidget = DeviceAvatar.yubiKeyData(
          deviceData,
          selected: true,
        );
      } else {
        deviceWidget = DeviceAvatar.deviceNode(
          deviceNode,
          selected: true,
        );
      }
    } else {
      deviceWidget = const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.usb_off),
      );
    }

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
        title: Focus(
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              node.focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (context) {
            return TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).setFilter(value);
              },
              textInputAction: TextInputAction.next,
              onSubmitted: (value) {
                Focus.of(context).focusInDirection(TraversalDirection.down);
              },
            );
          }),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: OverflowBox(
                maxHeight: 44,
                maxWidth: 44,
                child: deviceWidget,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const MainActionsDialog(),
                );
              },
            ),
          ),
        ],
      ),
      drawer: const MainPageDrawer(),
      body: _buildSubPage(subPage, deviceData),
    );
  }
}
