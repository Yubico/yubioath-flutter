import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';

class MainActionsDialog extends ConsumerWidget {
  const MainActionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(sortedDevicesProvider);
    final device = ref.watch(currentDeviceProvider);
    final actions = ref.watch(menuActionsProvider)(context);

    return SimpleDialog(
      //title: Text(device?.name ?? 'No YubiKey'),
      children: [
        ...devices.map((e) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: DeviceRow(
                e,
                selected: e == device,
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(currentDeviceProvider.notifier).setCurrentDevice(e);
                },
              ),
            )),
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

class DeviceRow extends StatelessWidget {
  final DeviceNode device;
  final bool selected;
  final Function() onPressed;
  const DeviceRow(
    this.device, {
    this.selected = false,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        children: [
          DeviceAvatar(
            device,
            selected: selected,
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                'S/N: ${device.info.serial} F/W: ${device.info.version}',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
