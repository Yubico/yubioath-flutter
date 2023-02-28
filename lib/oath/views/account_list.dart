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

import '../../widgets/list_title.dart';
import '../models.dart';
import '../state.dart';
import 'account_view.dart';

class AccountList extends ConsumerWidget {
  final List<OathPair> accounts;
  const AccountList(this.accounts, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final credentials = ref.watch(filteredCredentialsProvider(accounts));
    final favorites = ref.watch(favoritesProvider);
    if (credentials.isEmpty) {
      return Center(
        child: Text(l10n.l_no_accounts),
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
          if (pinnedCreds.isNotEmpty) ListTitle(l10n.w_pinned),
          ...pinnedCreds.map(
            (entry) => AccountView(
              entry.credential,
            ),
          ),
          if (creds.isNotEmpty) ListTitle(l10n.w_accounts),
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
