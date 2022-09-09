// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteCredentialDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final FidoCredential credential;
  const DeleteCredentialDialog(this.devicePath, this.credential, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = credential.userName;

    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.fido_delete_credential),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.fido_this_will_delete_cred),
            Text('${AppLocalizations.of(context)!.fido_credential}: $label'),
          ]
              .map((e) => Padding(
                    child: e,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(credentialProvider(devicePath).notifier)
                .deleteCredential(credential);
            await ref.read(withContextProvider)(
              (context) async {
                Navigator.of(context).pop(true);
                showMessage(context,
                    AppLocalizations.of(context)!.fido_credential_deleted);
              },
            );
          },
          child: Text(AppLocalizations.of(context)!.fido_delete),
        ),
      ],
    );
  }
}
