import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../about_page.dart';
import '../../settings_page.dart';
import '../models.dart';
import '../state.dart';

extension on SubPage {
  String get displayName {
    switch (this) {
      case SubPage.oath:
        return 'Authenticator';
      case SubPage.fido:
        return 'WebAuthn';
      case SubPage.otp:
        return 'One-Time Passwords';
      case SubPage.piv:
        return 'Certificates';
      case SubPage.management:
        return 'Toggle applications';
    }
  }
}

class MainPageDrawer extends ConsumerWidget {
  const MainPageDrawer({Key? key}) : super(key: key);

  IconData _iconFor(SubPage page) {
    switch (page) {
      case SubPage.oath:
        return Icons.supervisor_account;
      case SubPage.fido:
        return Icons.security;
      case SubPage.otp:
        return Icons.password;
      case SubPage.piv:
        return Icons.approval;
      case SubPage.management:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSubPage = ref.watch(subPageProvider);

    final mainPages = [SubPage.oath, SubPage.fido, SubPage.otp, SubPage.piv];

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
          ...mainPages.map((page) => DrawerItem(
                titleText: page.displayName,
                icon: Icon(_iconFor(page)),
                selected: page == currentSubPage,
                onTap: page != currentSubPage
                    ? () {
                        ref.read(subPageProvider.notifier).setSubPage(page);
                        Navigator.of(context).pop();
                      }
                    : null,
              )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Configuration',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          // PLACEHOLDER
          DrawerItem(
            titleText: 'Toggle applications',
            icon: Icon(_iconFor(SubPage.management)),
            selected: SubPage.management == currentSubPage,
            onTap: () {
              ref.read(subPageProvider.notifier).setSubPage(SubPage.management);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Application',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          DrawerItem(
            titleText: 'Settings',
            icon: const Icon(Icons.settings),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
            },
          ),
          DrawerItem(
            titleText: 'About',
            icon: const Icon(Icons.help_outline),
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
