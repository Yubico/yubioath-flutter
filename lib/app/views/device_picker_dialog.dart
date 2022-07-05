import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class DevicePickerDialog extends ConsumerWidget {
  const DevicePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(attachedDevicesProvider).toList();
    final currentNode = ref.watch(currentDeviceProvider);

    final Widget hero;
    final bool showUsb;
    if (currentNode != null) {
      showUsb = devices.whereType<UsbYubiKeyNode>().isEmpty;
      devices.removeWhere((e) => e.path == currentNode.path);
      hero = _CurrentDeviceRow(
        currentNode,
        ref.watch(currentDeviceDataProvider),
        onTap: () {
          Navigator.of(context).pop();
        },
      );
    } else {
      hero = ListTile(
        leading: DeviceAvatar(
          selected: true,
          child: Icon(Platform.isAndroid ? Icons.no_cell : Icons.usb),
        ),
        title: Text(Platform.isAndroid ? 'No YubiKey' : 'USB'),
        subtitle: Text(Platform.isAndroid
            ? 'Insert or tap a YubiKey'
            : 'Insert a YubiKey'),
        onTap: () {
          Navigator.of(context).pop();
        },
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
            Navigator.of(context).pop();
            ref.read(currentDeviceProvider.notifier).setCurrentDevice(null);
          },
        ),
      ...devices.map(
        (e) => _DeviceRow(
          e,
          info: e.map(
            usbYubiKey: (node) => node.info,
            nfcReader: (_) => null,
          ),
          onTap: () {
            Navigator.of(context).pop();
            ref.read(currentDeviceProvider.notifier).setCurrentDevice(e);
          },
        ),
      ),
    ];

    return SimpleDialog(
      children: [
        hero,
        if (others.isNotEmpty) const Divider(),
        ...others,
      ],
    );
  }
}

class _CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final AsyncValue<YubiKeyData> data;
  final Function() onTap;

  const _CurrentDeviceRow(
    this.node,
    this.data, {
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => data.when(
        data: (data) {
          final isNfc = data.node is NfcReaderNode;
          return ListTile(
            leading: DeviceAvatar.yubiKeyData(
              data,
              selected: true,
            ),
            isThreeLine: isNfc,
            title: Text(isNfc ? node.name : data.name),
            subtitle: Text(isNfc
                ? '${data.name}\n${_getSubtitle(data.info)}'
                : _getSubtitle(data.info)),
            onTap: onTap,
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
          return ListTile(
            leading: DeviceAvatar.deviceNode(
              node,
              selected: true,
            ),
            title: Text(message),
            subtitle: Text(node.name),
            onTap: onTap,
          );
        },
        loading: () => ListTile(
          leading: DeviceAvatar.deviceNode(
            node,
            selected: true,
          ),
          title: const Text('No YubiKey present'),
          subtitle: Text(node.name),
          onTap: onTap,
        ),
      );
}

class _DeviceRow extends StatelessWidget {
  final DeviceNode node;
  final DeviceInfo? info;
  final Function() onTap;

  const _DeviceRow(
    this.node, {
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      onTap: onTap,
    );
  }
}
