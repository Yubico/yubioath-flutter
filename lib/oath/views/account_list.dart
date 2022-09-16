import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import 'account_view.dart';

class AccountList extends ConsumerWidget {
  final List<OathPair> accounts;
  const AccountList(this.accounts, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(filteredCredentialsProvider(accounts));
    final favorites = ref.watch(favoritesProvider);
    if (credentials.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.oath_no_credentials),
      );
    }

    final pinnedCreds =
        credentials.where((entry) => favorites.contains(entry.credential.id));
    final creds =
        credentials.where((entry) => !favorites.contains(entry.credential.id));

    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Column(
        children: [
          if (pinnedCreds.isNotEmpty)
            ListTitle(AppLocalizations.of(context)!.oath_pinned),
          ...pinnedCreds.map(
            (entry) => AccountView(
              entry.credential,
            ),
          ),
          if (creds.isNotEmpty)
            ListTitle(AppLocalizations.of(context)!.oath_accounts),
          ...creds.map(
            (entry) => AccountView(
              entry.credential,
            ),
          ),
        ],
      ),
    );
  }
}
