/*
 * Copyright (C) 2022-2025 Yubico.
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../android/state.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'keys.dart' as keys;
import 'keys.dart';

class DevicePickerContent extends ConsumerWidget {
  final bool extended;

  const DevicePickerContent({super.key, this.extended = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hidden = ref.watch(hiddenDevicesProvider);
    final devices = ref
        .watch(attachedDevicesProvider)
        .where((e) => !hidden.contains(e.path.key))
        .toList();
    final currentNode = ref.watch(currentDeviceProvider);

    final showUsb = isDesktop && devices.whereType<UsbYubiKeyNode>().isEmpty;

    Widget? androidNoKeyWidget;
    if (isAndroid && devices.isEmpty) {
      var hasNfcSupport = ref.watch(androidNfcSupportProvider);
      var isNfcEnabled = ref.watch(androidNfcAdapterState);
      final subtitle = hasNfcSupport && isNfcEnabled
          ? l10n.l_insert_or_tap_yk
          : l10n.l_insert_yk;

      androidNoKeyWidget = _DeviceRow(
        leading: const DeviceAvatar(
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Symbols.usb),
        )),
        title: l10n.l_no_yk_present,
        subtitle: subtitle,
        onTap: () {
          ref.read(currentDeviceProvider.notifier).setCurrentDevice(null);
        },
        selected: currentNode == null,
        extended: extended,
      );
    }

    List<Widget> children = [
      if (showUsb)
        _DeviceRow(
          leading: const DeviceAvatar(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Symbols.usb),
          )),
          title: l10n.s_usb,
          subtitle: l10n.l_no_yk_present,
          onTap: () {
            ref.read(currentDeviceProvider.notifier).setCurrentDevice(null);
          },
          selected: currentNode == null,
          extended: extended,
        ),
      if (androidNoKeyWidget != null) androidNoKeyWidget,
      ...devices.map(
        (e) => e.path == currentNode?.path
            ? _buildCurrentDeviceRow(
                context,
                ref,
                e,
                ref.watch(currentDeviceDataProvider),
                extended,
              )
            : e.map(
                usbYubiKey: (node) => _buildDeviceRow(
                  context,
                  ref,
                  node,
                  node.info,
                  extended,
                ),
                nfcReader: (node) => _NfcDeviceRow(node, extended: extended),
              ),
      ),
    ];

    return Column(children: children);
  }
}

String _getDeviceInfoString(BuildContext context, DeviceInfo info) {
  final l10n = AppLocalizations.of(context);
  final serial = info.serial;
  return [
    if (serial != null) l10n.s_sn_serial(serial),
    if (info.version.isAtLeast(1))
      l10n.s_fw_version(info.version)
    else
      l10n.s_unknown_type,
  ].join(' ');
}

List<String> _getDeviceStrings(
    BuildContext context, DeviceNode node, AsyncValue<YubiKeyData> data) {
  final l10n = AppLocalizations.of(context);
  final messages = data.whenOrNull(
        data: (data) => [data.name, _getDeviceInfoString(context, data.info)],
        error: (error, _) => switch (error) {
          'device-inaccessible' => [node.name, l10n.s_yk_inaccessible],
          'unknown-device' => [l10n.s_unknown_device],
          'restricted-nfc' => [l10n.s_restricted_nfc],
          _ => null,
        },
      ) ??
      [l10n.l_no_yk_present];

  // Add the NFC reader name, unless it's already included (as device name, like on Android)
  if (node is NfcReaderNode && !messages.contains(node.name)) {
    messages.add(node.name);
  }

  return messages;
}

class _DeviceMenuButton extends ConsumerWidget {
  final List<PopupMenuItem> menuItems;
  final double opacity;

  const _DeviceMenuButton({required this.menuItems, required this.opacity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(Navigator.of(context).context), // use app theme
      child: Opacity(
        opacity: menuItems.isNotEmpty ? opacity : 0.0,
        child: PopupMenuButton(
          key: yubikeyPopupMenuButton,
          enabled: menuItems.isNotEmpty,
          icon: const Icon(Symbols.more_horiz),
          tooltip: '',
          iconColor: Theme.of(context).listTileTheme.textColor,
          itemBuilder: (context) {
            return menuItems;
          },
          popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        ),
      ),
    );
  }
}

class _DeviceRow extends ConsumerStatefulWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool extended;
  final bool selected;
  final Color? background;
  final DeviceNode? node;
  final void Function() onTap;

  const _DeviceRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.extended,
    required this.selected,
    this.background,
    this.node,
    required this.onTap,
  });

  @override
  ConsumerState<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends ConsumerState<_DeviceRow> {
  bool _showContextMenu = false;

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems(context, ref, widget.node);
    final tooltip = '${widget.title}\n${widget.subtitle}';
    final themeData = Theme.of(context);
    final seedColor = !widget.selected || widget.background == null
        ? themeData.colorScheme.primary
        : widget.background!;
    final colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor, brightness: themeData.brightness);
    final localThemeData = widget.selected
        ? themeData.copyWith(
            colorScheme: colorScheme,
            listTileTheme: themeData.listTileTheme.copyWith(
              tileColor: widget.background != null
                  ? colorScheme.primary
                  : themeData.colorScheme.primary,
              textColor: widget.selected ? colorScheme.onPrimary : null,
              iconColor: widget.selected ? colorScheme.onPrimary : null,
            ),
          )
        : themeData;
    if (widget.extended) {
      return Tooltip(
        message: '', // no tooltip for drawer
        child: Theme(
          data: localThemeData,
          child: MouseRegion(
            onEnter: (PointerEnterEvent event) {
              setState(() {
                _showContextMenu = true;
              });
            },
            onExit: (PointerExitEvent event) {
              setState(() {
                _showContextMenu = false;
              });
            },
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              horizontalTitleGap: 8,
              leading: widget.leading,
              trailing: menuItems.isNotEmpty
                  ? _DeviceMenuButton(
                      menuItems: menuItems,
                      opacity: widget.selected
                          ? 1.0
                          : _showContextMenu
                              ? 0.3
                              : 0.0,
                    )
                  : null,
              title: Text(
                widget.title,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              subtitle: Text(
                widget.subtitle,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              dense: true,
              onTap: widget.onTap,
            ),
          ),
        ),
      );
    } else {
      void showMenuFn(details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            0,
          ),
          items: menuItems,
        );
      }

      return GestureDetector(
        onSecondaryTapDown:
            isDesktop && menuItems.isNotEmpty ? showMenuFn : null,
        onLongPressStart: isAndroid ? showMenuFn : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          child: widget.selected
              ? Semantics(
                  label: tooltip,
                  child: IconButton.filled(
                    tooltip: isDesktop ? tooltip : null,
                    icon: widget.leading,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: widget.onTap,
                  ))
              : Semantics(
                  label: tooltip,
                  child: IconButton(
                    tooltip: isDesktop ? tooltip : null,
                    icon: widget.leading,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: widget.onTap,
                    color: colorScheme.secondary,
                  )),
        ),
      );
    }
  }

  List<PopupMenuItem> _getMenuItems(
      BuildContext context, WidgetRef ref, DeviceNode? node) {
    final l10n = AppLocalizations.of(context);
    final hidden = ref.watch(hiddenDevicesProvider);

    return [
      if (isDesktop && hidden.isNotEmpty)
        PopupMenuItem(
          enabled: hidden.isNotEmpty,
          onTap: () {
            ref.read(hiddenDevicesProvider.notifier).showAll();
          },
          child: ListTile(
            title: Text(l10n.s_show_hidden_readers),
            leading: const Icon(Symbols.visibility),
            dense: true,
            contentPadding: EdgeInsets.zero,
            enabled: hidden.isNotEmpty,
          ),
        ),
      if (isDesktop && node is NfcReaderNode)
        PopupMenuItem(
          onTap: () {
            ref.read(hiddenDevicesProvider.notifier).hideDevice(node.path);
          },
          child: ListTile(
            title: Text(l10n.s_hide_reader),
            leading: const Icon(Symbols.visibility_off),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
    ];
  }
}

_DeviceRow _buildDeviceRow(
  BuildContext context,
  WidgetRef ref,
  DeviceNode node,
  DeviceInfo? info,
  bool extended,
) {
  final l10n = AppLocalizations.of(context);
  final subtitle = node.when(
    usbYubiKey: (_, __, ___, info) => info == null
        ? l10n.s_yk_inaccessible
        : _getDeviceInfoString(context, info),
    nfcReader: (_, __) => l10n.s_select_to_scan,
  );

  final keyCustomization =
      ref.watch(keyCustomizationManagerProvider)[info?.serial];
  String displayName = keyCustomization?.name ?? node.name;

  return _DeviceRow(
    key: ValueKey(node.path.key),
    leading: DeviceAvatar.deviceNode(node),
    title: displayName,
    subtitle: subtitle,
    extended: extended,
    selected: false,
    node: node,
    onTap: () {
      ref.read(currentDeviceProvider.notifier).setCurrentDevice(node);
    },
  );
}

_DeviceRow _buildCurrentDeviceRow(
  BuildContext context,
  WidgetRef ref,
  DeviceNode node,
  AsyncValue<YubiKeyData> data,
  bool extended,
) {
  final messages = _getDeviceStrings(context, node, data);
  if (messages.length > 2) {
    // Don't show reader name
    messages.removeLast();
  }
  final title = messages.removeAt(0);
  final subtitle = messages.join('\n');

  final keyCustomization =
      ref.watch(keyCustomizationManagerProvider)[data.valueOrNull?.info.serial];
  String displayName = keyCustomization?.name ?? title;
  Color? displayColor = keyCustomization?.color;

  return _DeviceRow(
    key: keys.deviceInfoListTile,
    leading: data.maybeWhen(
      data: (data) =>
          DeviceAvatar.yubiKeyData(data, radius: extended ? null : 16),
      orElse: () => DeviceAvatar.deviceNode(node, radius: extended ? null : 16),
    ),
    title: displayName,
    subtitle: subtitle,
    extended: extended,
    background: displayColor,
    selected: true,
    node: node,
    onTap: () {},
  );
}

class _NfcDeviceRow extends ConsumerWidget {
  final DeviceNode node;
  final bool extended;

  const _NfcDeviceRow(this.node, {required this.extended});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _buildDeviceRow(context, ref, node, null, extended);
}
