import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class ResetDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const ResetDialog(this.devicePath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    return ResponsiveDialog(
      title: const Text('Factory reset'),
      child: Column(
        children: [
          const Text(
              'Warning! This will irrevocably delete all OATH TOTP/HOTP accounts from your YubiKey.'),
          Text(
            'Your OATH credentials, as well as any password set, will be removed from this YubiKey. Make sure to first disable these from their respective web sites to avoid being locked out of your accounts.',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ]
            .map((e) => Padding(
                  child: e,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(oathStateProvider(devicePath).notifier).reset();
            Navigator.of(context).pop();
            showMessage(context, 'OATH application reset');
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
