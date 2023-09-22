/*
 * Copyright (C) 2023 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../management/views/management_screen.dart';
import '../message.dart';
import '../models.dart';
import '../shortcuts.dart';
import '../state.dart';
import 'device_picker.dart';
import 'keys.dart';

class NavigationItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final bool collapsed;
  final bool selected;
  final void Function() onTap;

  const NavigationItem({
    super.key,
    required this.leading,
    required this.title,
    this.collapsed = false,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: selected
            ? Theme(
                data: theme.copyWith(
                    colorScheme: colorScheme.copyWith(
                        primary: colorScheme.secondaryContainer,
                        onPrimary: colorScheme.onSecondaryContainer)),
                child: IconButton.filled(
                  icon: leading,
                  tooltip: title,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: onTap,
                ),
              )
            : IconButton(
                icon: leading,
                tooltip: title,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: onTap,
              ),
      );
    } else {
      return Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
          leading: leading,
          title: Text(title),
          minVerticalPadding: 16,
          onTap: onTap,
          tileColor: selected ? colorScheme.secondaryContainer : null,
          textColor: selected ? colorScheme.onSecondaryContainer : null,
          iconColor: selected ? colorScheme.onSecondaryContainer : null,
        ),
      );
    }
  }
}

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

class NavigationContent extends ConsumerWidget {
  final bool shouldPop;
  final bool extended;
  const NavigationContent(
      {super.key, this.shouldPop = true, this.extended = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final supportedApps = ref.watch(supportedAppsProvider);
    final data = ref.watch(currentDeviceDataProvider).valueOrNull;

    final availableApps = data != null
        ? supportedApps
            .where(
                (app) => app.getAvailability(data) != Availability.unsupported)
            .toList()
        : <Application>[];
    final hasManagement = availableApps.remove(Application.management);
    final currentApp = ref.watch(currentAppProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: DevicePickerContent(extended: extended),
          ),

          const SizedBox(height: 32),

          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: Column(
              children: [
                if (data != null) ...[
                  // Normal YubiKey Applications
                  ...availableApps.map((app) => NavigationItem(
                        title: app.getDisplayName(l10n),
                        leading: app == currentApp
                            ? Icon(app._filledIcon)
                            : Icon(app._icon),
                        collapsed: !extended,
                        selected: app == currentApp,
                        onTap: () {
                          ref
                              .read(currentAppProvider.notifier)
                              .setCurrentApp(app);
                          if (shouldPop) {
                            Navigator.of(context).pop();
                          }
                        },
                      )),
                  // Management app
                  if (hasManagement) ...[
                    NavigationItem(
                      key: managementAppDrawer,
                      leading: Icon(Application.management._icon),
                      title: l10n.s_toggle_applications,
                      collapsed: !extended,
                      onTap: () {
                        showBlurDialog(
                          context: context,
                          // data must be non-null when index == 0
                          builder: (context) => ManagementScreen(data),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),

          // Non-YubiKey pages
          NavigationItem(
            leading: const Icon(Icons.settings_outlined),
            title: l10n.s_settings,
            collapsed: !extended,
            onTap: () {
              if (shouldPop) {
                Navigator.of(context).pop();
              }
              Actions.maybeInvoke(context, const SettingsIntent());
            },
          ),
          NavigationItem(
            leading: const Icon(Icons.help_outline),
            title: l10n.s_help_and_about,
            collapsed: !extended,
            onTap: () {
              if (shouldPop) {
                Navigator.of(context).pop();
              }
              Actions.maybeInvoke(context, const AboutIntent());
            },
          ),
        ],
      ),
    );
  }
}
