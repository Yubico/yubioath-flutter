import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../models.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class DeleteFingerprintDialog extends ConsumerWidget {
  final DevicePath devicePath;
  final Fingerprint fingerprint;
  const DeleteFingerprintDialog(this.devicePath, this.fingerprint, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = fingerprint.label;

    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.fido_delete_fingerprint),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(fingerprintProvider(devicePath).notifier)
                .deleteFingerprint(fingerprint);
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop(true);
              showMessage(context,
                  AppLocalizations.of(context)!.fido_fingerprint_deleted);
            });
          },
          child: Text(AppLocalizations.of(context)!.fido_delete),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.fido_this_will_delete_fp),
          Text('${AppLocalizations.of(context)!.fido_fingerprint}: $label'),
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
