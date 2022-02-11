import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../about_page.dart';
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
        primary: false, //Prevents conflict with the MainPage scroll view.
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Yubico Authenticator',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          const Divider(),
          ...SubPage.values.map((page) => DrawerItem(
                titleText: page.displayName,
                icon: const Icon(Icons.miscellaneous_services),
                selected: page == currentSubPage,
                onTap: page != currentSubPage
                    ? () {
                        ref.read(subPageProvider.notifier).setSubPage(page);
                        Navigator.of(context).pop();
                      }
                    : null,
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'CONFIGURATION',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          DrawerItem(
            titleText: 'Placeholder Light mode',
            icon: const Icon(Icons.alarm),
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
              Navigator.of(context).pop();
            },
          ),
          DrawerItem(
            titleText: 'Placeholder Dark mode',
            icon: const Icon(Icons.house),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          DrawerItem(
            titleText: 'About Yubico Authenticator',
            icon: const Icon(Icons.settings_applications),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..push(
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
            },
          ),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final bool selected;
  final String titleText;
  final Icon icon;
  final void Function()? onTap;

  const DrawerItem({
    required this.titleText,
    required this.icon,
    this.onTap,
    this.selected = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        dense: true,
        selected: selected,
        selectedColor: Theme.of(context).backgroundColor,
        selectedTileColor: Theme.of(context).colorScheme.secondary,
        leading: icon,
        title: Text(titleText),
        onTap: onTap,
      ),
    );
  }
}
