import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:collection/collection.dart';

import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

Function _listEquals = const ListEquality().equals;

class MainActionsDialog extends ConsumerWidget {
  const MainActionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(attachedDevicesProvider).toList();
    final currentNode = ref.watch(currentDeviceProvider);
    final data = ref.watch(currentDeviceDataProvider);
    final actions = ref.watch(menuActionsProvider)(context);

    if (currentNode != null) {
      devices.removeWhere((e) => _listEquals(e.path, currentNode.path));
    }

    return SimpleDialog(
      children: [
        if (currentNode != null)
          CurrentDeviceRow(
            currentNode,
            data?.name,
            info: data?.info,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ...devices.map(
          (e) => DeviceRow(
            e,
            e.name,
            info: e.when(
              usbYubiKey: (path, name, pid, info) => info,
              nfcReader: (path, name) => null,
            ),
            selected: false,
            onTap: () {
              Navigator.of(context).pop();
              ref.read(currentDeviceProvider.notifier).setCurrentDevice(e);
            },
          ),
        ),
        if (actions.isNotEmpty) const Divider(),
        ...actions.map((a) => ListTile(
              dense: true,
              leading: a.icon,
              title: Text(a.text),
              onTap: () {
                Navigator.of(context).pop();
                a.action?.call();
              },
            )),
      ],
    );
  }
}

class CurrentDeviceRow extends StatelessWidget {
  final DeviceNode node;
  final String? name;
  final DeviceInfo? info;
  final Function() onTap;

  const CurrentDeviceRow(
    this.node,
    this.name, {
    required this.info,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subtitle = node is NfcReaderNode
        ? info != null
            ? '${node.name}\nS/N: ${info!.serial} F/W: ${info!.version}'
            : node.name
        : 'S/N: ${info!.serial} F/W: ${info!.version}';
    return ListTile(
      leading: DeviceAvatar(
        node,
        name ?? '',
        info,
        selected: true,
      ),
      title: Text(name ?? 'No YubiKey present'),
      isThreeLine: subtitle.contains('\n'),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class DeviceRow extends StatelessWidget {
  final DeviceNode node;
  final String name;
  final DeviceInfo? info;
  final bool selected;
  final Function() onTap;

  const DeviceRow(
    this.node,
    this.name, {
    required this.info,
    required this.onTap,
    this.selected = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DeviceAvatar(
        node,
        name,
        info,
        selected: selected,
      ),
      title: Text(name),
      subtitle: Text(
        info == null
            ? (selected ? 'No YubiKey present' : 'Select to scan')
            : 'S/N: ${info!.serial} F/W: ${info!.version}',
      ),
      onTap: onTap,
    );
  }
}
