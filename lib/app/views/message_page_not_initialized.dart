/*
 * Copyright (C) 2024-2025 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../../android/app_methods.dart';
import '../../android/state.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../state.dart';
import 'message_page.dart';

class MessagePageNotInitialized extends ConsumerWidget {
  final String title;
  final List<Capability>? capabilities;

  const MessagePageNotInitialized(
      {super.key, required this.title, required this.capabilities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final noKeyImage = Image.asset(
      'assets/graphics/no-key.png',
      filterQuality: FilterQuality.medium,
      scale: 2,
      color: Theme.of(context).colorScheme.primary,
    );

    if (isAndroid) {
      var hasNfcSupport = ref.watch(androidNfcSupportProvider);
      var isNfcEnabled = ref.watch(androidNfcAdapterState);
      var isUsbYubiKey =
          ref.watch(attachedDevicesProvider).firstOrNull?.transport ==
              Transport.usb;
      return MessagePage(
        title: title,
        capabilities: capabilities,
        centered: true,
        delayedContent: isUsbYubiKey,
        graphic: noKeyImage,
        header: hasNfcSupport && isNfcEnabled
            ? l10n.l_insert_or_tap_yk
            : l10n.l_insert_yk,
        actionsBuilder: (context, expanded) => [
          if (hasNfcSupport && !isNfcEnabled)
            ElevatedButton.icon(
                label: Text(l10n.s_enable_nfc),
                icon: const Icon(Symbols.contactless),
                onPressed: () async {
                  await openNfcSettings();
                })
        ],
      );
    } else {
      return MessagePage(
        title: title,
        capabilities: capabilities,
        centered: true,
        delayedContent: false,
        graphic: noKeyImage,
        header: l10n.l_insert_yk,
      );
    }
  }
}
