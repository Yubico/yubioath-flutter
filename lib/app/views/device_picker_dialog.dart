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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'device_utils.dart';

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

class DevicePickerDialog extends StatefulWidget {
  const DevicePickerDialog({super.key});

  @override
  State<StatefulWidget> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends State<DevicePickerDialog> {
  late FocusScopeNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusScopeNode();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This keeps the focus in the dialog, even if the underlying page
    // changes as it does when a new device is selected.
    return FocusScope(
      node: _focus,
      autofocus: true,
      onFocusChange: (focused) {
        if (!focused) {
          _focus.requestFocus();
        }
      },
      child: const _DevicePickerContent(),
    );
  }
}

class _DevicePickerContent extends ConsumerWidget {
  const _DevicePickerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(_hiddenDevicesProvider);
    final devices = ref
        .watch(attachedDevicesProvider)
        .where((e) => !hidden.contains(e.path.key))
        .toList();
    final currentNode = ref.watch(currentDeviceProvider);

    final Widget hero;
    final bool showUsb;
    if (currentNode != null) {
      showUsb = isDesktop && devices.whereType<UsbYubiKeyNode>().isEmpty;
      devices.removeWhere((e) => e.path == currentNode.path);
      hero = _CurrentDeviceRow(
        currentNode,
        ref.watch(currentDeviceDataProvider),
      );
    } else {
      hero = Column(
        children: [
          _HeroAvatar(
            child: DeviceAvatar(
              radius: 64,
              child: Icon(Platform.isAndroid ? Icons.no_cell : Icons.usb),
            ),
          ),
          ListTile(
            title:
                Center(child: Text(Platform.isAndroid ? 'No YubiKey' : 'USB')),
            subtitle: Center(
              child: Text(Platform.isAndroid
                  ? 'Insert or tap a YubiKey'
                  : 'Insert a YubiKey'),
            ),
          ),
        ],
      );
      showUsb = false;
    }

    List<Widget> others = [
      if (showUsb)
        ListTile(
          leading: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: DeviceAvatar(child: Icon(Icons.usb)),
          ),
          title: const Text('USB'),
          subtitle: const Text('No YubiKey present'),
          onTap: () {
            ref.read(currentDeviceProvider.notifier).setCurrentDevice(null);
          },
        ),
      ...devices.map(
        (e) => e.map(
          usbYubiKey: (node) => _DeviceRow(node, info: node.info),
          nfcReader: (node) => _NfcDeviceRow(node),
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
                    child: const ListTile(
                      title: Text('Show hidden devices'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
      child: SimpleDialog(
        children: [
          hero,
          if (others.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(),
            ),
          ...others,
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final Widget child;
  const _HeroAvatar({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            theme.colorScheme.background,
            theme.colorScheme.background.withOpacity(0.4),
            (theme.dialogTheme.backgroundColor ?? theme.dialogBackgroundColor)
                .withOpacity(0),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Theme(
        // Give the avatar a transparent background
        data: theme.copyWith(
            colorScheme:
                theme.colorScheme.copyWith(background: Colors.transparent)),
        child: child,
      ),
    );
  }
}

class _CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final AsyncValue<YubiKeyData> data;

  const _CurrentDeviceRow(this.node, this.data);

  @override
  Widget build(BuildContext context) {
    final hero = data.maybeWhen(
      data: (data) => DeviceAvatar.yubiKeyData(data, radius: 64),
      orElse: () => DeviceAvatar.deviceNode(node, radius: 64),
    );
    final messages = getDeviceMessages(node, data);

    return Column(
      children: [
        _HeroAvatar(child: hero),
        ListTile(
          title: Text(messages.removeAt(0), textAlign: TextAlign.center),
          isThreeLine: messages.length > 1,
          subtitle: Text(messages.join('\n'), textAlign: TextAlign.center),
        )
      ],
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  final DeviceNode node;
  final DeviceInfo? info;

  const _DeviceRow(this.node, {this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DeviceAvatar.deviceNode(node),
      ),
      title: Text(node.name),
      subtitle: Text(
        node.when(
          usbYubiKey: (_, __, ___, info) =>
              info == null ? 'Device inaccessible' : getDeviceInfoString(info),
          nfcReader: (_, __) => 'Select to scan',
        ),
      ),
      onTap: () {
        ref.read(currentDeviceProvider.notifier).setCurrentDevice(node);
      },
    );
  }
}

class _NfcDeviceRow extends ConsumerWidget {
  final DeviceNode node;

  const _NfcDeviceRow(this.node);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                title: const Text('Show hidden devices'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                enabled: hidden.isNotEmpty,
              ),
            ),
            PopupMenuItem(
              onTap: () {
                ref.read(_hiddenDevicesProvider.notifier).hideDevice(node.path);
              },
              child: const ListTile(
                title: Text('Hide device'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      },
      child: _DeviceRow(node),
    );
  }
}
