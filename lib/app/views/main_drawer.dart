import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../management/views/management_screen.dart';
import '../../about_page.dart';
import '../../settings_page.dart';
import '../models.dart';
import '../state.dart';

extension on Application {
  IconData get _icon {
    switch (this) {
      case Application.oath:
        return Icons.supervisor_account;
      case Application.fido:
        return Icons.security;
      case Application.otp:
        return Icons.password;
      case Application.piv:
        return Icons.approval;
      case Application.management:
        return Icons.construction;
      case Application.openpgp:
        return Icons.key;
      case Application.hsmauth:
        return Icons.key;
    }
  }
}

class MainPageDrawer extends ConsumerWidget {
  final bool shouldPop;
  const MainPageDrawer({this.shouldPop = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportedApps = ref.watch(supportedAppsProvider);
    final data = ref.watch(currentDeviceDataProvider);
    final currentApp = ref.watch(currentAppProvider);

    return Drawer(
      child: ListView(
        primary: false, //Prevents conflict with the MainPage scroll view.
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Yubico Authenticator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (data != null) ...[
            // Normal YubiKey Applications
            ...supportedApps
                .where((app) =>
                    app != Application.management &&
                    app.getAvailability(data) != Availability.unsupported)
                .map((app) => ApplicationItem(
                      app: app,
                      available:
                          app.getAvailability(data) == Availability.enabled,
                      selected: app == currentApp,
                      onSelect: () {
                        if (shouldPop) Navigator.of(context).pop();
                      },
                    )),
            // Management app
            if (supportedApps.contains(Application.management) &&
                Application.management.getAvailability(data) ==
                    Availability.enabled) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Configuration',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              DrawerItem(
                titleText: 'Toggle applications',
                icon: Icon(Application.management._icon),
                onTap: () {
                  if (shouldPop) Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => ManagementScreen(data),
                  );
                },
              ),
              const Divider(),
            ],
          ],
          // Non-YubiKey pages
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Application',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          DrawerItem(
            titleText: 'Settings',
            icon: const Icon(Icons.settings),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showDialog(
                  context: context, builder: (context) => const SettingsPage());
            },
          ),
          DrawerItem(
            titleText: 'Help and feedback',
            icon: const Icon(Icons.help),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showDialog(
                  context: context, builder: (context) => const AboutPage());
            },
          ),
        ],
      ),
    );
  }
}

class ApplicationItem extends ConsumerWidget {
  final Application app;
  final bool available;
  final bool selected;
  final Function onSelect;
  const ApplicationItem({
    required this.app,
    required this.available,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DrawerItem(
      titleText: app.displayName,
      icon: Icon(app._icon),
      selected: selected,
      enabled: available,
      onTap: available & !selected
          ? () {
              ref.read(currentAppProvider.notifier).setCurrentApp(app);
              onSelect();
            }
          : null,
    );
  }
}

class DrawerItem extends StatelessWidget {
  final bool enabled;
  final bool selected;
  final String titleText;
  final Icon icon;
  final void Function()? onTap;

  const DrawerItem({
    required this.titleText,
    required this.icon,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ListTile(
        enabled: enabled,
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
