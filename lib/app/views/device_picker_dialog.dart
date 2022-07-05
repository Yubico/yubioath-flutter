import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state.dart';
import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

String _getSubtitle(DeviceInfo info) {
  final serial = info.serial;
  var subtitle = '';
  if (serial != null) {
    subtitle += 'S/N: $serial ';
  }
  subtitle += 'F/W: ${info.version}';
  return subtitle;
}

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

class DevicePickerDialog extends ConsumerWidget {
  const DevicePickerDialog({super.key});

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
      showUsb = devices.whereType<UsbYubiKeyNode>().isEmpty;
      devices.removeWhere((e) => e.path == currentNode.path);
      hero = _CurrentDeviceRow(
        currentNode,
        ref.watch(currentDeviceDataProvider),
      );
    } else {
      hero = Column(
        children: [
          DeviceAvatar(
            selected: true,
            radius: 64,
            child: Icon(Platform.isAndroid ? Icons.no_cell : Icons.usb),
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
            child: DeviceAvatar(
              radius: 20,
              child: Icon(Icons.usb),
            ),
          ),
          title: const Text('USB'),
          subtitle: const Text('No YubiKey present'),
          onTap: () {
            //Navigator.of(context).pop();
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

class _CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final AsyncValue<YubiKeyData> data;

  const _CurrentDeviceRow(this.node, this.data);

  @override
  Widget build(BuildContext context) => data.when(
        data: (data) {
          final isNfc = data.node is NfcReaderNode;
          return Column(
            children: [
              DeviceAvatar.yubiKeyData(
                data,
                selected: true,
                radius: 64,
              ),
              ListTile(
                isThreeLine: isNfc,
                title: Center(child: Text(data.name)),
                subtitle: Column(
                  children: [
                    Text(_getSubtitle(data.info)),
                    if (isNfc) Text(node.name),
                  ],
                ),
                //onTap: onTap,
              ),
            ],
          );
        },
        error: (error, _) {
          final String message;
          switch (error) {
            case 'unknown-device':
              message = 'Unrecognized device';
              break;
            default:
              message = 'No YubiKey present';
          }
          return Column(
            children: [
              DeviceAvatar.deviceNode(
                node,
                selected: true,
                radius: 64,
              ),
              ListTile(
                title: Center(child: Text(message)),
                subtitle: Center(child: Text(node.name)),
              ),
            ],
          );
        },
        loading: () => Column(
          children: [
            DeviceAvatar.deviceNode(
              node,
              selected: true,
              radius: 64,
            ),
            ListTile(
              title: Center(child: Text(node.name)),
              subtitle: const Center(child: Text('Device inaccessible')),
            ),
          ],
        ),
      );
}

class _DeviceRow extends ConsumerWidget {
  final DeviceNode node;
  final DeviceInfo? info;

  const _DeviceRow(
    this.node, {
    this.info,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DeviceAvatar.deviceNode(
          node,
          radius: 20,
        ),
      ),
      title: Text(node.name),
      subtitle: Text(
        node.when(
          usbYubiKey: (_, __, ___, info) =>
              info == null ? 'Device inaccessible' : _getSubtitle(info),
          nfcReader: (_, __) => 'Select to scan',
        ),
      ),
      onTap: () {
        //Navigator.of(context).pop();
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
