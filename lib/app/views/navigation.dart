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

extension on Section {
  IconData get _icon => switch (this) {
        Section.home => Symbols.home,
        Section.accounts => Symbols.supervisor_account,
        Section.securityKey => Symbols.security_key,
        Section.passkeys => Symbols.passkey,
        Section.fingerprints => Symbols.fingerprint,
        Section.slots => Symbols.touch_app,
        Section.certificates => Symbols.id_card,
      };

  Key get _key => switch (this) {
        Section.home => homeDrawer,
        Section.accounts => oathAppDrawer,
        Section.securityKey => u2fAppDrawer,
        Section.passkeys => fidoPasskeysAppDrawer,
        Section.fingerprints => fidoFingerprintsAppDrawer,
        Section.slots => otpAppDrawer,
        Section.certificates => pivAppDrawer,
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
    final supportedSections = ref.watch(supportedSectionsProvider);
    final data = ref.watch(currentDeviceDataProvider).valueOrNull;

    final availableSections = data != null
        ? supportedSections
            .where((section) =>
                section.getAvailability(data) != Availability.unsupported)
            .toList()
        : [Section.home];
    final currentSection = ref.watch(currentSectionProvider);

    return Padding(
      padding:
          const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 12),
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
                ...availableSections.map((app) => NavigationItem(
                      key: app._key,
                      title: app.getDisplayName(l10n),
                      leading: Icon(
                        app._icon,
                        fill: app == currentSection ? 1.0 : 0.0,
                        semanticLabel:
                            !extended ? app.getDisplayName(l10n) : null,
                      ),
                      collapsed: !extended,
                      selected: app == currentSection,
                      onTap: data == null && currentSection == Section.home ||
                              data != null &&
                                  app.getAvailability(data) ==
                                      Availability.enabled
                          ? () {
                              ref
                                  .read(currentSectionProvider.notifier)
                                  .setCurrentSection(app);
                              if (shouldPop) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
