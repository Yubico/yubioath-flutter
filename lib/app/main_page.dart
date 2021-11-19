import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'no_device_screen.dart';
import 'device_info_screen.dart';
import 'models.dart';
import 'state.dart';

import '../../about_page.dart';
import '../../oath/oath_screen.dart';

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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          )
        ],
      ),
      drawer: MainPageDrawer(
        subPage,
        onSelect: (page) {
          ref.read(subPageProvider.notifier).setSubPage(page);
          Navigator.of(context).pop();
        },
      ),
      body: currentDevice == null
          ? const NoDeviceScreen()
          : _buildSubPage(subPage, currentDevice),
    );
  }
}

extension on SubPage {
  String get displayName {
    switch (this) {
      case SubPage.authenticator:
        return 'Authenticator';
      case SubPage.yubikey:
        return 'YubiKey';
    }
  }
}

class MainPageDrawer extends StatelessWidget {
  final SubPage currentSubPage;
  final void Function(SubPage) onSelect;
  const MainPageDrawer(this.currentSubPage, {required this.onSelect, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Hello'),
          ),
          ...SubPage.values.map((value) => ListTile(
                title: Text(
                  value.displayName,
                  style: Theme.of(context).textTheme.headline6,
                ),
                tileColor: value == currentSubPage ? Colors.blueGrey : null,
                enabled: value != currentSubPage,
                onTap: () {
                  onSelect(value);
                },
              )),
        ],
      ),
    );
  }
}
