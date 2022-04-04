import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../management/models.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

class DevicePickerDialog extends ConsumerWidget {
  const DevicePickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(attachedDevicesProvider).toList();
    final currentNode = ref.watch(currentDeviceProvider);
    final data = ref.watch(currentDeviceDataProvider);

    if (currentNode != null) {
      devices.removeWhere((e) => e.path == currentNode.path);
    }

    return SimpleDialog(
      children: [
        currentNode == null
            ? ListTile(
                leading: const DeviceAvatar(child: Icon(Icons.no_cell)),
                title: const Text('No YubiKey'),
                subtitle: Text(Platform.isAndroid
                    ? 'Insert or tap a YubiKey'
                    : (devices.isEmpty
                        ? 'Insert a YubiKey'
                        : 'Insert a YubiKey, or select an item below')),
              )
            : _CurrentDeviceRow(
                currentNode,
                data: data,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
        if (devices.isNotEmpty) const Divider(),
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
      ],
    );
  }
}

class _CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final YubiKeyData? data;
  final Function() onTap;

  const _CurrentDeviceRow(
    this.node, {
    this.data,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return node.when(usbYubiKey: (path, name, pid, info) {
      if (info != null) {
        return ListTile(
          leading: DeviceAvatar.yubiKeyData(
            data!,
            selected: true,
          ),
          title: Text(name),
          subtitle: Text('S/N: ${info.serial} F/W: ${info.version}'),
          onTap: onTap,
        );
      } else {
        {
          return ListTile(
            leading: DeviceAvatar.deviceNode(
              node,
              selected: true,
            ),
            title: Text(name),
            subtitle: const Text('Device inaccessible'),
            onTap: onTap,
          );
        }
      }
    }, nfcReader: (path, name) {
      final info = data?.info;
      if (info != null) {
        return ListTile(
          leading: DeviceAvatar.yubiKeyData(
            data!,
            selected: true,
          ),
          title: Text(data!.name),
          isThreeLine: true,
          subtitle: Text('$name\nS/N: ${info.serial} F/W: ${info.version}'),
          onTap: onTap,
        );
      } else {
        return ListTile(
          leading: DeviceAvatar.deviceNode(
            node,
            selected: true,
          ),
          title: const Text('No YubiKey present'),
          subtitle: Text(name),
          onTap: onTap,
        );
      }
    });
  }
}

class _DeviceRow extends StatelessWidget {
  final DeviceNode node;
  final DeviceInfo? info;
  final Function() onTap;

  const _DeviceRow(
    this.node, {
    required this.info,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DeviceAvatar.deviceNode(node),
      title: Text(node.name),
      subtitle: Text(
        node.when(
          usbYubiKey: (_, __, ___, info) => info == null
              ? 'Device inaccessible'
              : 'S/N: ${info.serial} F/W: ${info.version}',
          nfcReader: (_, __) => 'Select to scan',
        ),
      ),
      onTap: onTap,
    );
  }
}
