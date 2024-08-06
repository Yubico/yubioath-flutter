import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';

class EnableEnterpriseAttestationDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const EnableEnterpriseAttestationDialog(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ResponsiveDialog(
      title: Text(l10n.s_enable_ep_attestation),
      actions: [
        TextButton(
          onPressed: () async {
            await ref
                .read(fidoStateProvider(devicePath).notifier)
                .enableEnterpriseAttestation();
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop();
              showMessage(context, l10n.s_ep_attestation_enabled);
            });
          },
          child: Text(l10n.s_enable),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.p_enable_ep_attestation_desc),
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
