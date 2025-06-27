/*
 * Copyright (C) 2023-2025 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../generated/l10n/app_localizations.dart';
import '../models.dart';
import '../state.dart';
import 'device_picker.dart';
import 'keys.dart';

class NavigationItem extends StatefulWidget {
  final Widget leading;
  final String title;
  final bool collapsed;
  final bool selected;
  final void Function()? onTap;
  final BorderRadiusGeometry? borderRadius;

  const NavigationItem({
    super.key,
    required this.leading,
    required this.title,
    this.collapsed = false,
    this.selected = false,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<StatefulWidget> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<NavigationItem> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child:
            widget.selected
                ? Theme(
                  data: theme.copyWith(
                    colorScheme: colorScheme.copyWith(
                      primary: colorScheme.secondaryContainer,
                      onPrimary: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  child: IconButton.filled(
                    focusNode: _focusNode,
                    icon: widget.leading,
                    tooltip: widget.title,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: widget.onTap,
                  ),
                )
                : IconButton(
                  focusNode: _focusNode,
                  icon: widget.leading,
                  tooltip: widget.title,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: widget.onTap,
                ),
      );
    } else {
      return ListTile(
        enabled: widget.onTap != null,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(48),
        ),
        leading: widget.leading,
        title: Text(widget.title),
        minVerticalPadding: 14.5,
        onTap: widget.onTap,
        tileColor: widget.selected ? colorScheme.secondaryContainer : null,
        textColor: widget.selected ? colorScheme.onSecondaryContainer : null,
        iconColor: widget.selected ? colorScheme.onSecondaryContainer : null,
        contentPadding: const EdgeInsets.only(left: 16.0),
      );
    }
  }
}

extension SectionUi on Section {
  IconData get _icon => switch (this) {
    Section.home => Symbols.home,
    Section.accounts => Symbols.supervisor_account,
    Section.securityKey => Symbols.security_key,
    Section.passkeys => Symbols.passkey,
    Section.fingerprints => Symbols.fingerprint,
    Section.slots => Symbols.touch_app,
    Section.certificates => Symbols.id_card,
    Section.settings => Symbols.settings,
  };

  Key get key => switch (this) {
    Section.home => homeDrawer,
    Section.accounts => oathAppDrawer,
    Section.securityKey => u2fAppDrawer,
    Section.passkeys => fidoPasskeysAppDrawer,
    Section.fingerprints => fidoFingerprintsAppDrawer,
    Section.slots => otpAppDrawer,
    Section.certificates => pivAppDrawer,
    Section.settings => settingsDrawer,
  };
}

final _moreItemKey = GlobalKey();

class MoreItem extends ConsumerWidget {
  final List<Section> sections;
  final bool collapsed;
  const MoreItem({super.key, required this.sections, this.collapsed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return MenuAnchor(
      menuChildren:
          sections
              .map(
                (e) => ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 150),
                  child: MenuItemButton(
                    leadingIcon: Icon(e._icon),
                    onPressed: () {
                      ref
                          .read(currentSectionProvider.notifier)
                          .setCurrentSection(e);
                    },
                    child: Text(e.getDisplayName(l10n)),
                  ),
                ),
              )
              .toList(),
      builder:
          (context, controller, child) => NavigationItem(
            leading: Icon(Symbols.more_horiz),
            title: 'More',
            collapsed: collapsed,
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
    );
  }
}

class NavigationContent extends ConsumerWidget {
  final bool shouldPop;
  final bool extended;
  final bool shouldCollapse;
  final bool isDrawer;
  final double appHeight;
  const NavigationContent({
    super.key,
    this.shouldPop = true,
    this.extended = false,
    this.shouldCollapse = true,
    this.isDrawer = false,
    required this.appHeight,
  });

  Widget _buildAppListContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Section> visibleSections,
    List<Section> hiddenSections,
    Section currentSection,
    YubiKeyData? data,
    bool scrollable,
  ) {
    final settingsSection = Section.settings;
    return AnimatedSize(
      duration: Duration(milliseconds: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Normal YubiKey Applications
          Flexible(
            child: ClipRect(
              child: Column(
                children: [
                  ...visibleSections.map(
                    (app) => Flexible(
                      flex: !scrollable && !shouldCollapse ? 0 : 1,
                      child: NavigationItem(
                        key: app.key,
                        title: app.getDisplayName(l10n),
                        borderRadius:
                            isDrawer
                                ? BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                )
                                : null,
                        leading: Icon(
                          app._icon,
                          fill: app == currentSection ? 1.0 : 0.0,
                          semanticLabel:
                              !extended ? app.getDisplayName(l10n) : null,
                        ),
                        collapsed: !extended,
                        selected: app == currentSection,
                        onTap:
                            data == null &&
                                        [
                                          Section.home,
                                          Section.settings,
                                        ].contains(currentSection) ||
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
                      ),
                    ),
                  ),
                  if (hiddenSections.isNotEmpty)
                    MoreItem(
                      key: _moreItemKey,
                      sections: hiddenSections,
                      collapsed: !extended,
                    ),
                ],
              ),
            ),
          ),
          NavigationItem(
            key: settingsSection.key,
            borderRadius:
                isDrawer
                    ? BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    )
                    : null,
            title: settingsSection.getDisplayName(l10n),
            leading: Icon(
              settingsSection._icon,
              fill: settingsSection == currentSection ? 1.0 : 0.0,
              semanticLabel:
                  !extended ? settingsSection.getDisplayName(l10n) : null,
            ),
            collapsed: !extended,
            selected: settingsSection == currentSection,
            onTap: () {
              ref
                  .read(currentSectionProvider.notifier)
                  .setCurrentSection(settingsSection);
              if (shouldPop) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Section> appSections,
    Section currentSection,
    bool scrollable,
    YubiKeyData? data,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: isDrawer ? 0.0 : 8.0,
        right: 8.0,
        bottom: 8.0,
        top: 12,
      ),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: DevicePickerContent(extended: extended, isDrawer: isDrawer),
          ),
          const SizedBox(height: 32),
          !scrollable && shouldCollapse
              ? Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalHeight = constraints.maxHeight;
                    final itemHeight = 60;
                    final hasMore = _moreItemKey.currentContext != null;
                    final appListHeight =
                        (totalHeight - itemHeight) - (hasMore ? itemHeight : 0);
                    var maxVisibleApps = (appListHeight / itemHeight)
                        .floor()
                        .clamp(0, appSections.length);

                    var visibleApps = appSections.take(maxVisibleApps).toList();
                    if (visibleApps.isNotEmpty &&
                        currentSection != Section.settings &&
                        !visibleApps.contains(currentSection)) {
                      visibleApps.removeLast();
                      visibleApps.add(currentSection);
                    }
                    List<Section> hiddenApps =
                        Set<Section>.from(
                          appSections,
                        ).difference(Set.from(visibleApps)).toList();

                    return _buildAppListContent(
                      context,
                      ref,
                      l10n,
                      visibleApps,
                      hiddenApps,
                      currentSection,
                      data,
                      scrollable,
                    );
                  },
                ),
              )
              : _buildAppListContent(
                context,
                ref,
                l10n,
                shouldCollapse ? [] : appSections,
                shouldCollapse ? appSections : [],
                currentSection,
                data,
                scrollable,
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final supportedSections = ref.watch(supportedSectionsProvider);
    final data = ref.watch(currentDeviceDataProvider).valueOrNull;

    final availableSections =
        data != null
            ? supportedSections
                .where(
                  (section) =>
                      section.getAvailability(data) != Availability.unsupported,
                )
                .toList()
            : [Section.home];
    final settingsSection = Section.settings;
    final appSections =
        availableSections.where((s) => s != settingsSection).toList();
    final currentSection = ref.watch(currentSectionProvider);

    final height = appHeight - kToolbarHeight - 1;
    final shouldScroll = height <= 270 && shouldCollapse;
    final content = _buildMainContent(
      context,
      ref,
      l10n,
      appSections,
      currentSection,
      shouldScroll,
      data,
    );
    if (shouldScroll) {
      return SingleChildScrollView(child: content);
    } else {
      return content;
    }
  }
}
