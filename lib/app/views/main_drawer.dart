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
    final data =
        ref.watch(currentDeviceDataProvider).whenOrNull(data: (data) => data);
    final currentApp = ref.watch(currentAppProvider);

    MediaQuery? mediaQuery =
        context.findAncestorWidgetOfExactType<MediaQuery>();
    final width = mediaQuery?.data.size.width ?? 400;

    return Drawer(
      width: width < 357 ? 0.85 * width : null,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0))),
      child: ListView(
        primary: false, //Prevents conflict with the MainPage scroll view.
        children: [
          const SizedBox(height: 24.0),
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
            ],
            const Divider(indent: 16.0, endIndent: 28.0),
          ],
          // Non-YubiKey pages
          DrawerItem(
            titleText: 'Settings',
            icon: const Icon(Icons.settings),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showDialog(
                context: context,
                builder: (context) => const SettingsPage(),
                routeSettings: const RouteSettings(name: 'settings'),
              );
            },
          ),
          DrawerItem(
            titleText: 'Help and about',
            icon: const Icon(Icons.help),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showDialog(
                context: context,
                builder: (context) => const AboutPage(),
                routeSettings: const RouteSettings(name: 'about'),
              );
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
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: ListTile(
        enabled: enabled,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        dense: true,
        minLeadingWidth: 24,
        minVerticalPadding: 18,
        selected: selected,
        selectedColor: Theme.of(context).colorScheme.onPrimary,
        selectedTileColor: Theme.of(context).colorScheme.primary,
        leading: IconTheme.merge(
          data: const IconThemeData(size: 24),
          child: icon,
        ),
        title: Text(titleText),
        onTap: onTap,
      ),
    );
  }
}
