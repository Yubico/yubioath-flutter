/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../about_page.dart';
import '../../android/views/android_settings_page.dart';
import '../../management/views/management_screen.dart';
import '../../settings_page.dart';
import '../message.dart';
import '../models.dart';
import '../state.dart';
import 'keys.dart';

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

    final color =
        Theme.of(context).brightness == Brightness.dark ? 'white' : 'green';

    return Drawer(
      width: width < 357 ? 0.85 * width : null,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0))),
      child: ListView(
        primary: false, //Prevents conflict with the MainPage scroll view.
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 19.0, left: 30.0, bottom: 12.0),
            child: Image.asset(
              'assets/graphics/yubico-$color.png',
              alignment: Alignment.centerLeft,
              height: 28,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const Divider(indent: 16.0, endIndent: 28.0),
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
                titleText:
                    AppLocalizations.of(context)!.mainDrawer_txt_applications,
                icon: Icon(Application.management._icon),
                key: managementAppDrawer,
                onTap: () {
                  if (shouldPop) Navigator.of(context).pop();
                  showBlurDialog(
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
            titleText: AppLocalizations.of(context)!.mainDrawer_txt_settings,
            icon: const Icon(Icons.settings),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showBlurDialog(
                context: context,
                builder: (context) => Platform.isAndroid
                    ? const AndroidSettingsPage()
                    : const SettingsPage(),
                routeSettings: const RouteSettings(name: 'settings'),
              );
            },
          ),
          DrawerItem(
            titleText: AppLocalizations.of(context)!.mainDrawer_txt_help,
            icon: const Icon(Icons.help),
            onTap: () {
              final nav = Navigator.of(context);
              if (shouldPop) nav.pop();
              showBlurDialog(
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
