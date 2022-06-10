import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/user_cancelled_exception.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteAccountDialog extends ConsumerWidget {
  final DeviceNode device;
  final OathCredential credential;
  const DeleteAccountDialog(this.device, this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If current device changes, we need to pop back to the main Page.
    ref.listen<DeviceNode?>(currentDeviceProvider, (previous, next) {
      Navigator.of(context).pop(false);
    });

    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return ResponsiveDialog(
      title: const Text('Delete account'),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await ref
                  .read(credentialListProvider(device.path).notifier)
                  .deleteAccount(credential);
              await ref.read(withContextProvider)(
                    (context) async {
                  Navigator.of(context).pop();
                  showMessage(context, 'Account deleted');
                },
              );
            } on UserCancelledException catch (_) {
              // ignored
            }
          },
          child: const Text('Delete'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Warning! This action will delete the account from your YubiKey.'),
          Text(
            'You will no longer be able to generate OTPs for this account. Make sure to first disable this credential from the website to avoid being locked out of your account.',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Text('Account: $label'),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: e,
                ))
            .toList(),
      ),
    );
  }
}
