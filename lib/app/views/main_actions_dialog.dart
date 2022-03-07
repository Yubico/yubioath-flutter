import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/management/models.dart';

import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

class MainActionsDialog extends ConsumerWidget {
  const MainActionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(attachedDevicesProvider).toList();
    final currentNode = ref.watch(currentDeviceProvider);
    final data = ref.watch(currentDeviceDataProvider);
    final actions = ref.watch(menuActionsProvider);

    if (currentNode != null) {
      devices.removeWhere((e) => e.path == currentNode.path);
    }

    return SimpleDialog(
      children: [
        if (currentNode != null)
          _CurrentDeviceRow(
            currentNode,
            data: data,
            onTap: () {
              Navigator.of(context).pop();
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
        if (currentNode == null && devices.isEmpty)
          Center(
              child: Text(
            'No YubiKey found',
            style: Theme.of(context).textTheme.titleMedium,
          )),
        if (actions.isNotEmpty) const Divider(),
        ...actions.map((a) => ListTile(
              dense: true,
              leading: a.icon,
              title: Text(a.text),
              onTap: () {
                Navigator.of(context).pop();
                a.action?.call(context);
              },
            )),
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
