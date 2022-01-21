import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteAccountDialog extends ConsumerWidget {
  final DeviceNode device;
  final OathCredential credential;
  const DeleteAccountDialog(this.device, this.credential, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop();
    });

    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return AlertDialog(
      title: Text('Delete $label?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Warning! This action will delete the account from your YubiKey.'),
          const Text(''),
          Text(
            'You will no longer be able to generate OTPs for this account. Make sure to first disable this credential from the website to avoid being locked out of your account.',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(credentialListProvider(device.path).notifier)
                .deleteAccount(credential);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}
