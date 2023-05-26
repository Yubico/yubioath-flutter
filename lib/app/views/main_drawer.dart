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

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../management/views/management_screen.dart';
import '../message.dart';
import '../models.dart';
import '../shortcuts.dart';
import '../state.dart';
import 'keys.dart';

extension on Application {
  IconData get _icon => switch (this) {
        Application.oath => Icons.supervisor_account_outlined,
        Application.fido => Icons.security_outlined,
        Application.otp => Icons.password_outlined,
        Application.piv => Icons.approval_outlined,
        Application.management => Icons.construction_outlined,
        Application.openpgp => Icons.key_outlined,
        Application.hsmauth => Icons.key_outlined,
      };

  IconData get _filledIcon => switch (this) {
        Application.oath => Icons.supervisor_account,
        Application.fido => Icons.security,
        Application.otp => Icons.password,
        Application.piv => Icons.approval,
        Application.management => Icons.construction,
        Application.openpgp => Icons.key,
        Application.hsmauth => Icons.key,
      };
}

class MainPageDrawer extends ConsumerWidget {
  final bool shouldPop;
  const MainPageDrawer({this.shouldPop = true, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supportedApps = ref.watch(supportedAppsProvider);
    final data = ref.watch(currentDeviceDataProvider).valueOrNull;
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

          switch (index) {
            case 0:
              showBlurDialog(
                context: context,
                // data must be non-null when index == 0
                builder: (context) => ManagementScreen(data!),
              );
              break;
            case 1:
              Actions.maybeInvoke(context, const SettingsIntent());
              break;
            case 2:
              Actions.maybeInvoke(context, const AboutIntent());
              break;
          }
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
                label: Text(app.getDisplayName(l10n)),
                icon: Icon(app._icon),
                selectedIcon: Icon(app._filledIcon),
              )),
          // Management app
          if (hasManagement) ...[
            NavigationDrawerDestination(
              key: managementAppDrawer,
              label: Text(
                l10n.s_toggle_applications,
              ),
              icon: Icon(Application.management._icon),
              selectedIcon: Icon(Application.management._filledIcon),
            ),
          ],
          const Divider(indent: 16.0, endIndent: 28.0),
        ],
        // Non-YubiKey pages
        NavigationDrawerDestination(
          label: Text(l10n.s_settings),
          icon: const Icon(Icons.settings_outlined),
        ),
        NavigationDrawerDestination(
          label: Text(l10n.s_help_and_about),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    );
  }
}
