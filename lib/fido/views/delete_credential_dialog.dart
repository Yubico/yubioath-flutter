import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/views/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteCredentialDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final FidoCredential credential;
  const DeleteCredentialDialog(this.devicePath, this.credential, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop(false);
    });

    final label = credential.userName;

    return ResponsiveDialog(
      title: const Text('Delete credential'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This will delete the credential from your YubiKey.'),
          Text('Credential: $label'),
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
            await ref
                .read(credentialProvider(devicePath).notifier)
                .deleteCredential(credential);
            Navigator.of(context).pop(true);
            showMessage(context, 'Credential deleted');
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
