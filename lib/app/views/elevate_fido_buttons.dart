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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../desktop/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../message.dart';
import '../state.dart';

class ElevateFidoButtons extends ConsumerWidget {
  const ElevateFidoButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilledButton.icon(
          label: Text(l10n.s_request_access),
          icon: const Icon(Symbols.lock_open),
          onPressed: () async {
            final closeMessage = showMessage(
                context, l10n.l_elevating_permissions,
                duration: const Duration(seconds: 30));
            try {
              if (await ref.read(rpcProvider).requireValue.elevate()) {
                ref.invalidate(rpcStateProvider);
              } else {
                await ref.read(withContextProvider)((context) async =>
                    showMessage(context, l10n.s_permission_denied));
              }
            } finally {
              closeMessage();
            }
          },
        ),
        OutlinedButton.icon(
          label: Text(l10n.s_open_windows_settings),
          icon: const Icon(Symbols.open_in_new),
          onPressed: () async {
            await Process.start('powershell.exe', [
              '-NoProfile',
              '-Command',
              'Start',
              'ms-settings:signinoptions-launchsecuritykeyenrollment'
            ]);
          },
        )
      ],
    );
  }
}
