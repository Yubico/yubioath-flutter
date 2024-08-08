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

import '../../widgets/flex_box.dart';
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
    final theme = Theme.of(context);
    final labelStyle =
        theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary);
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

    final oathLayout = ref.watch(oathLayoutProvider);
    final pinnedLayout =
        (oathLayout == OathLayout.grid || oathLayout == OathLayout.mixed)
            ? FlexLayout.grid
            : FlexLayout.list;
    final normalLayout =
        oathLayout == OathLayout.grid ? FlexLayout.grid : FlexLayout.list;

    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pinnedCreds.isNotEmpty) ...[
              Text(l10n.s_pinned, style: labelStyle),
              const SizedBox(height: 8),
              FlexBox<OathPair>(
                items: pinnedCreds.toList(),
                itemBuilder: (value) => AccountView(
                  value.credential,
                  expanded: expanded,
                  selected: value.credential == selected,
                  large: pinnedLayout == FlexLayout.grid,
                ),
                cellMinWidth: 250,
                spacing: pinnedLayout == FlexLayout.grid ? 4.0 : 0.0,
                runSpacing: pinnedLayout == FlexLayout.grid ? 4.0 : 0.0,
                layout: pinnedLayout,
              ),
            ],
            if (pinnedCreds.isNotEmpty && creds.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.s_accounts,
                style: labelStyle,
              ),
              const SizedBox(height: 8),
            ],
            FlexBox<OathPair>(
              items: creds.toList(),
              itemBuilder: (value) => AccountView(
                value.credential,
                expanded: expanded,
                selected: value.credential == selected,
                large: normalLayout == FlexLayout.grid,
              ),
              cellMinWidth: 250,
              spacing: normalLayout == FlexLayout.grid ? 4.0 : 0.0,
              runSpacing: normalLayout == FlexLayout.grid ? 4.0 : 0.0,
              layout: normalLayout,
            ),
          ],
        ),
      ),
    );
  }
}
