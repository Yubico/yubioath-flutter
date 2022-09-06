import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../widgets/responsive_dialog.dart';
import '../state.dart';
import '../../app/models.dart';
import '../../app/state.dart';

class ResetDialog extends ConsumerWidget {
  final DevicePath devicePath;
  const ResetDialog(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveDialog(
      title: Text(AppLocalizations.of(context)!.oath_factory_reset),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(oathStateProvider(devicePath).notifier).reset();
            await ref.read(withContextProvider)((context) async {
              Navigator.of(context).pop();
              showMessage(context,
                  AppLocalizations.of(context)!.oath_oath_application_reset);
            });
          },
          child: Text(AppLocalizations.of(context)!.oath_reset),
        ),
      ],
      child: Column(
        children: [
          Text(AppLocalizations.of(context)!.oath_warning_will_delete_accounts),
          Text(
            AppLocalizations.of(context)!.oath_warning_disable_these_creds,
            style: Theme.of(context).textTheme.bodyText1,
          ),
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
