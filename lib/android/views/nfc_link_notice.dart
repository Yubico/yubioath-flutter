/*
 * Copyright (C) 2026 Yubico.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/views/keys.dart' as keys;
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/warning_list_item.dart';
import '../app_methods.dart';
import '../models.dart';
import '../state.dart';

/// Warning shown under the "On YubiKey NFC tap" title when this app does not
/// handle my.yubico.com links, which leaves every tap action without effect
/// from Android 16. Tapping it opens the system "Open by default" page.
///
/// Builds signed with Yubico's release key are verified automatically, so in
/// practice this appears only for builds signed with another key.
class NfcLinkNotice extends ConsumerWidget {
  final bool isDialog;

  const NfcLinkNotice({super.key, required this.isDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapAction = ref.watch(androidNfcTapActionProvider);
    final status = ref.watch(androidDomainVerificationStatusProvider).value;
    if (tapAction == NfcTapAction.noAction ||
        status != DomainVerificationStatus.none) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: isDialog
          ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
          : const EdgeInsets.symmetric(vertical: 8),
      child: WarningListItem(
        key: keys.nfcLinkNotice,
        title: l10n.l_nfc_tap_not_active,
        subtitle: l10n.l_nfc_tap_not_active_desc,
        onTap: openDomainVerificationSettings,
      ),
    );
  }
}
