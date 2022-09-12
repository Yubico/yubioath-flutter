import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yubico_authenticator/cancellation_exception.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../keys.dart' as keys;

class DeleteAccountDialog extends ConsumerWidget {
  final DeviceNode device;
  final OathCredential credential;
  const DeleteAccountDialog(this.device, this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = credential.issuer != null
        ? '${credential.issuer} (${credential.name})'
        : credential.name;

    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.oath_delete_account),
      actions: [
        TextButton(
          key: keys.deleteButton,
          onPressed: () async {
            try {
              await ref
                  .read(credentialListProvider(device.path).notifier)
                  .deleteAccount(credential);
              await ref.read(withContextProvider)(
                (context) async {
                  Navigator.of(context).pop(true);
                  showMessage(
                      context,
                      AppLocalizations.of(context)!
                          .oath_success_delete_account);
                },
              );
            } on CancellationException catch (_) {
              // ignored
            }
          },
          child: Text(AppLocalizations.of(context)!.oath_delete),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!
                .oath_warning_this_will_delete_account_from_key),
            Text(
              AppLocalizations.of(context)!.oath_warning_disable_this_cred,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text('${AppLocalizations.of(context)!.oath_account} $label'),
          ]
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: e,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
