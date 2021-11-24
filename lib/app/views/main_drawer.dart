import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';

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

class MainPageDrawer extends ConsumerWidget {
  const MainPageDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSubPage = ref.watch(subPageProvider);

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
                  ref.read(subPageProvider.notifier).setSubPage(value);
                  Navigator.of(context).pop();
                },
              )),
        ],
      ),
    );
  }
}
