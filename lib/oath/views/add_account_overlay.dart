import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddAccountOverlay extends StatelessWidget {
  const AddAccountOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;
    // TODO: use color from theme.
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
              color:
                  Color(darkMode ? 0xFF151515 : 0xFFE6E6E6).withOpacity(0.95),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
              borderRadius: const BorderRadius.all(Radius.circular(20.0))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                l10n.s_add_account,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12.0),
              Text(
                l10n.l_drop_qr_description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
