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

  Widget _buildPinnedAccountList(List<OathPair> pinnedCreds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int itemsPerRow = 1;
        if (width <= 500) {
          // single column
          itemsPerRow = 1;
        } else if (width <= 620) {
          // 2 column
          itemsPerRow = 2;
        } else {
          // 3 column
          itemsPerRow = 3;
        }

        List<List<OathPair>> chunks = [];
        final numChunks = (pinnedCreds.length / itemsPerRow).ceil();
        for (int i = 0; i < numChunks; i++) {
          final index = i * itemsPerRow;
          int endIndex = index + itemsPerRow;

          if (endIndex > pinnedCreds.length) {
            endIndex = pinnedCreds.length;
          }

          chunks.add(pinnedCreds.sublist(index, endIndex));
        }
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8.0),
          child: Column(
            children: [
              ...chunks.map(
                (c) => Row(
                  children: [
                    for (final entry in c) ...[
                      Flexible(
                        child: AccountView(
                          entry.credential,
                          expanded: expanded,
                          selected: entry.credential == selected,
                          pinned: true,
                        ),
                      ),
                      if (itemsPerRow != 1 && c.indexOf(entry) != c.length - 1)
                        const SizedBox(width: 8),
                    ],
                    if (c.length < itemsPerRow) ...[
                      // Prevents resizing when an account is unpinned
                      SizedBox(width: 8 * (itemsPerRow - c.length).toDouble()),
                      Spacer(
                        flex: itemsPerRow - c.length,
                      )
                    ]
                  ],
                ),
              )
            ]
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: e,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

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
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            if (pinnedCreds.isNotEmpty)
              _buildPinnedAccountList(pinnedCreds.toList()),
            ...creds.map(
              (entry) => AccountView(
                entry.credential,
                expanded: expanded,
                selected: entry.credential == selected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
