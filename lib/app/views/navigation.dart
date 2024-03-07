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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/state.dart';
import '../models.dart';
import '../state.dart';
import 'device_picker.dart';
import 'keys.dart';

class NavigationItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final bool collapsed;
  final bool selected;
  final void Function()? onTap;

  const NavigationItem({
    super.key,
    required this.leading,
    required this.title,
    this.collapsed = false,
    this.selected = false,
    this.onTap,
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
      return ListTile(
        enabled: onTap != null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
        leading: leading,
        title: Text(title),
        minVerticalPadding: 16,
        onTap: onTap,
        tileColor: selected ? colorScheme.secondaryContainer : null,
        textColor: selected ? colorScheme.onSecondaryContainer : null,
        iconColor: selected ? colorScheme.onSecondaryContainer : null,
        contentPadding: const EdgeInsets.only(left: 16.0),
      );
    }
  }
}

extension on Application {
  IconData get _icon => switch (this) {
        Application.accounts => Symbols.supervisor_account,
        Application.webauthn => Symbols.security_key,
        Application.passkeys => Symbols.passkey,
        Application.fingerprints => Symbols.fingerprint,
        Application.slots => Symbols.touch_app,
        Application.certificates => Symbols.approval,
        Application.management => Symbols.construction,
        Application.home => Symbols.home
      };

  Key get _key => switch (this) {
        Application.accounts => oathAppDrawer,
        Application.webauthn => u2fAppDrawer,
        Application.passkeys => fidoPasskeysAppDrawer,
        Application.fingerprints => fidoFingerprintsAppDrawer,
        Application.slots => otpAppDrawer,
        Application.certificates => pivAppDrawer,
        Application.management => managementAppDrawer,
        Application.home => homeDrawer,
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
        : !isAndroid // TODO: Remove check when Home is implemented on Android
            ? [Application.home]
            : <Application>[];
    availableApps.remove(Application.management);
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
                // Normal YubiKey Applications
                ...availableApps.map((app) => NavigationItem(
                      key: app._key,
                      title: app.getDisplayName(l10n),
                      leading:
                          Icon(app._icon, fill: app == currentApp ? 1.0 : 0.0),
                      collapsed: !extended,
                      selected: app == currentApp,
                      onTap: data == null && currentApp == Application.home ||
                              data != null &&
                                  app.getAvailability(data) ==
                                      Availability.enabled
                          ? () {
                              ref
                                  .read(currentAppProvider.notifier)
                                  .setCurrentApp(app);
                              if (shouldPop) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    )),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
