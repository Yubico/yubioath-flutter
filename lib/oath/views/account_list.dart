/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../state.dart';
import 'account_view.dart';

class AccountList extends ConsumerWidget {
  final List<OathPair> accounts;
  final bool expanded;
  final OathCredential? selected;
  const AccountList(this.accounts,
      {super.key, required this.expanded, this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final credentials = ref.watch(filteredCredentialsProvider(accounts));
    final favorites = ref.watch(favoritesProvider);
    if (credentials.isEmpty) {
      return Center(
        child: Text(l10n.s_no_accounts),
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
          ...pinnedCreds.map(
            (entry) => AccountView(
              entry.credential,
              expanded: expanded,
              selected: entry.credential == selected,
            ),
          ),
          if (pinnedCreds.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
          ...creds.map(
            (entry) => AccountView(
              entry.credential,
              expanded: expanded,
              selected: entry.credential == selected,
            ),
          ),
        ],
      ),
    );
  }
}
