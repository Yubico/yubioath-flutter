/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/models.dart';
import '../../core/state.dart';
import '../../desktop/state.dart';
import '../../home/views/home_message_page.dart';
import '../models.dart';
import '../state.dart';
import 'elevate_fido_buttons.dart';

class DeviceErrorScreen extends ConsumerWidget {
  final DeviceNode node;
  final Object? error;
  const DeviceErrorScreen(this.node, {this.error, super.key});

  Widget _buildUsbPid(BuildContext context, WidgetRef ref, UsbPid pid) {
    final l10n = AppLocalizations.of(context)!;
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows &&
          !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
        final currentSection = ref.read(currentSectionProvider);
        return HomeMessagePage(
          capabilities: currentSection.capabilities,
          header: l10n.l_admin_privileges_required,
          message: l10n.p_elevated_permissions_required,
          actionsBuilder: (context, expanded) => [
            const ElevateFidoButtons(),
          ],
          footnote: isMicrosoftStore ? l10n.l_ms_store_permission_note : null,
        );
      }
    }
    return HomeMessagePage(
      centered: true,
      graphic: Image.asset(
        'assets/product-images/generic.png',
        filterQuality: FilterQuality.medium,
        scale: 3,
        color: Theme.of(context).colorScheme.error,
      ),
      header: l10n.l_yk_no_access,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return node.map(
      usbYubiKey: (node) => _buildUsbPid(context, ref, node.pid),
      nfcReader: (node) => switch (error) {
        'unknown-device' => HomeMessagePage(
            centered: true,
            graphic: Icon(
              Symbols.help,
              size: 96,
              color: Theme.of(context).colorScheme.error,
            ),
            header: l10n.s_unknown_device,
          ),
        'restricted-nfc' => HomeMessagePage(
            centered: true,
            graphic: Icon(
              Symbols.contactless,
              size: 96,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            header: l10n.l_deactivate_restricted_nfc,
            message: l10n.p_deactivate_restricted_nfc_desc,
            footnote: l10n.p_deactivate_restricted_nfc_footer,
          ),
        'no-scp11b-nfc-support' => HomeMessagePage(
            centered: true,
            graphic: Icon(
              Symbols.contactless,
              size: 96,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            header: l10n.l_configuration_unsupported,
            message: l10n.p_scp_unsupported,
          ),
        _ => HomeMessagePage(
            centered: true,
            graphic: Image.asset(
              'assets/graphics/no-key.png',
              filterQuality: FilterQuality.medium,
              scale: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
            header: l10n.l_place_on_nfc_reader,
          ),
      },
    );
  }
}
