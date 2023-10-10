/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'package:shared_preferences/shared_preferences.dart';

import '../../android/state.dart';
import '../../core/state.dart';
import '../../management/models.dart';
import '../key_customization.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'keys.dart' as keys;

final _hiddenDevicesProvider =
    StateNotifierProvider<_HiddenDevicesNotifier, List<String>>(
        (ref) => _HiddenDevicesNotifier(ref.watch(prefProvider)));

class _HiddenDevicesNotifier extends StateNotifier<List<String>> {
  static const String _key = 'DEVICE_PICKER_HIDDEN';
  final SharedPreferences _prefs;

  _HiddenDevicesNotifier(this._prefs) : super(_prefs.getStringList(_key) ?? []);

  void showAll() {
    state = [];
    _prefs.setStringList(_key, state);
  }

  void hideDevice(DevicePath devicePath) {
    state = [...state, devicePath.key];
    _prefs.setStringList(_key, state);
  }
}

class DevicePickerContent extends ConsumerWidget {
  final bool extended;

  const DevicePickerContent({required this.extended, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(_hiddenDevicesProvider);
    final devices = ref
        .watch(attachedDevicesProvider)
        .where((e) => !hidden.contains(e.path.key))
        .toList();
    final currentNode = ref.watch(currentDeviceProvider);

    final showUsb = isDesktop && devices.whereType<UsbYubiKeyNode>().isEmpty;

    Widget? androidNoKeyWidget;
    if (isAndroid && devices.isEmpty) {
      var hasNfcSupport = ref.watch(androidNfcSupportProvider);
      var isNfcEnabled = ref.watch(androidNfcStateProvider);
      final subtitle = hasNfcSupport && isNfcEnabled
          ? l10n.l_insert_or_tap_yk
          : l10n.l_insert_yk;

      androidNoKeyWidget = _DeviceRow(
        leading: const DeviceAvatar(child: Icon(Icons.usb)),
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
          leading: const DeviceAvatar(child: Icon(Icons.usb)),
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

    return GestureDetector(
      onSecondaryTapDown: hidden.isEmpty
          ? null
          : (details) {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  details.globalPosition.dx,
                  0,
                ),
                items: [
                  PopupMenuItem(
                    onTap: () {
                      ref.read(_hiddenDevicesProvider.notifier).showAll();
                    },
                    child: ListTile(
                      title: Text(l10n.s_show_hidden_devices),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
      child: Column(children: children),
    );
  }
}

String _getDeviceInfoString(BuildContext context, DeviceInfo info) {
  final l10n = AppLocalizations.of(context)!;
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
  final l10n = AppLocalizations.of(context)!;
  final messages = data.whenOrNull(
        data: (data) => [data.name, _getDeviceInfoString(context, data.info)],
        error: (error, _) => switch (error) {
          'device-inaccessible' => [node.name, l10n.s_yk_inaccessible],
          'unknown-device' => [l10n.s_unknown_device],
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

class _DeviceRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool extended;
  final bool selected;
  final Color? background;
  final void Function() onTap;

  const _DeviceRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.extended,
    required this.selected,
    this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tooltip = '$title\n$subtitle';
    final colorScheme = Theme.of(context).colorScheme;
    if (extended) {
      return Tooltip(
        message: tooltip,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          horizontalTitleGap: 8,
          leading: leading,
          title: Text(title, overflow: TextOverflow.fade, softWrap: false),
          subtitle:
              Text(subtitle, overflow: TextOverflow.fade, softWrap: false),
          dense: true,
          tileColor:
              selected ? colorScheme.primary : background?.withOpacity(0.3),
          textColor: selected ? colorScheme.onPrimary : null,
          iconColor: selected ? colorScheme.onPrimary : null,
          onTap: onTap,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.5),
        child: selected
            ? IconButton.filled(
                tooltip: tooltip,
                icon: leading,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: onTap,
              )
            : IconButton(
                tooltip: tooltip,
                icon: leading,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: onTap,
                color: colorScheme.secondary,
              ),
      );
    }
  }
}

_DeviceRow _buildDeviceRow(
  BuildContext context,
  WidgetRef ref,
  DeviceNode node,
  DeviceInfo? info,
  bool extended,
) {
  final l10n = AppLocalizations.of(context)!;
  final subtitle = node.when(
    usbYubiKey: (_, __, ___, info) => info == null
        ? l10n.s_yk_inaccessible
        : _getDeviceInfoString(context, info),
    nfcReader: (_, __) => l10n.s_select_to_scan,
  );

  String displayName = node.name;
  Color? displayColor;
  if (info?.serial != null) {
    final properties = ref
        .read(keyCustomizationManagerProvider)
        .get(info?.serial?.toString())
        ?.properties;
    var customizedName = properties?['display_name'];
    if (customizedName != null && customizedName != '') {
      displayName = customizedName + ' (${node.name})';
    }
    var displayColorCustomization = properties?['display_color'];
    if (displayColorCustomization != null) {
      displayColor = Color(int.parse(displayColorCustomization, radix: 16));
    }
  }

  return _DeviceRow(
    key: ValueKey(node.path.key),
    leading: IconTheme(
      // Force the standard icon theme
      data: IconTheme.of(context),
      child: DeviceAvatar.deviceNode(node, ref),
    ),
    title: displayName,
    subtitle: subtitle,
    extended: extended,
    background: displayColor,
    selected: false,
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
    // Don't show readername
    messages.removeLast();
  }
  final title = messages.removeAt(0);
  final subtitle = messages.join('\n');

  String displayName = title;
  Color? displayColor;
  if (node is UsbYubiKeyNode) {
    if (node.info?.serial != null) {
      final properties = ref
          .read(keyCustomizationManagerProvider)
          .get(node.info?.serial.toString())
          ?.properties;
      var customizedName = properties?['display_name'];
      if (customizedName != null && customizedName != '') {
        displayName = customizedName + ' (${node.name})';
      }
      var displayColorCustomization = properties?['display_color'];
      if (displayColorCustomization != null) {
        displayColor = Color(int.parse(displayColorCustomization, radix: 16));
      }
    }
  }

  return _DeviceRow(
    key: keys.deviceInfoListTile,
    leading: data.maybeWhen(
      data: (data) =>
          DeviceAvatar.yubiKeyData(data, ref, radius: extended ? null : 16),
      orElse: () =>
          DeviceAvatar.deviceNode(node, ref, radius: extended ? null : 16),
    ),
    title: displayName,
    subtitle: subtitle,
    extended: extended,
    background: displayColor,
    selected: true,
    onTap: () {},
  );
}

class _NfcDeviceRow extends ConsumerWidget {
  final DeviceNode node;
  final bool extended;

  const _NfcDeviceRow(this.node, {required this.extended});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(_hiddenDevicesProvider);
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            0,
          ),
          items: [
            PopupMenuItem(
              enabled: hidden.isNotEmpty,
              onTap: () {
                ref.read(_hiddenDevicesProvider.notifier).showAll();
              },
              child: ListTile(
                title: Text(l10n.s_show_hidden_devices),
                dense: true,
                contentPadding: EdgeInsets.zero,
                enabled: hidden.isNotEmpty,
              ),
            ),
            PopupMenuItem(
              onTap: () {
                ref.read(_hiddenDevicesProvider.notifier).hideDevice(node.path);
              },
              child: ListTile(
                title: Text(l10n.s_hide_device),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      },
      child: _buildDeviceRow(context, ref, node, null, extended),
    );
  }
}
