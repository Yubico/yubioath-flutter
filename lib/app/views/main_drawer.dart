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
        return Icons.supervisor_account_outlined;
      case Application.fido:
        return Icons.security_outlined;
      case Application.otp:
        return Icons.password_outlined;
      case Application.piv:
        return Icons.approval_outlined;
      case Application.management:
        return Icons.construction_outlined;
      case Application.openpgp:
        return Icons.key_outlined;
      case Application.hsmauth:
        return Icons.key_outlined;
    }
  }

  IconData get _filledIcon {
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
    final data = ref.watch(currentDeviceDataProvider).value;
    final color =
        Theme.of(context).brightness == Brightness.dark ? 'white' : 'green';

    final availableApps = data != null
        ? supportedApps
            .where(
                (app) => app.getAvailability(data) != Availability.unsupported)
            .toList()
        : <Application>[];
    final hasManagement = availableApps.remove(Application.management);

    return NavigationDrawer(
      selectedIndex: availableApps.indexOf(ref.watch(currentAppProvider)),
      onDestinationSelected: (index) {
        if (shouldPop) Navigator.of(context).pop();

        if (index < availableApps.length) {
          // Switch to selected app
          final app = availableApps[index];
          ref.read(currentAppProvider.notifier).setCurrentApp(app);
        } else {
          // Handle action
          index -= availableApps.length;

          if (!hasManagement) {
            index++;
          }

          Widget Function(BuildContext) dialogBuilder;
          RouteSettings? routeSettings;
          switch (index) {
            case 0:
              dialogBuilder = (context) => ManagementScreen(data!);
              break;
            case 1:
              dialogBuilder = (context) => Platform.isAndroid
                  ? const AndroidSettingsPage()
                  : const SettingsPage();
              routeSettings = const RouteSettings(name: 'settings');
              break;
            case 2:
              dialogBuilder = (context) => const AboutPage();
              routeSettings = const RouteSettings(name: 'about');
              break;
            default:
              return;
          }
          showBlurDialog(
            context: context,
            builder: dialogBuilder,
            routeSettings: routeSettings,
          );
        }
      },
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
          ...availableApps.map((app) => NavigationDrawerDestination(
                label: Text(app.displayName),
                icon: Icon(app._icon),
                selectedIcon: Icon(app._filledIcon),
              )),
          // Management app
          if (hasManagement) ...[
            NavigationDrawerDestination(
              key: managementAppDrawer,
              label: Text(
                AppLocalizations.of(context)!.mainDrawer_txt_applications,
              ),
              icon: Icon(Application.management._icon),
              selectedIcon: Icon(Application.management._filledIcon),
            ),
          ],
          const Divider(indent: 16.0, endIndent: 28.0),
        ],
        // Non-YubiKey pages
        NavigationDrawerDestination(
          label: Text(AppLocalizations.of(context)!.mainDrawer_txt_settings),
          icon: const Icon(Icons.settings_outlined),
        ),
        NavigationDrawerDestination(
          label: Text(AppLocalizations.of(context)!.mainDrawer_txt_help),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    );
  }
}
