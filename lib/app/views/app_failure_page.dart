/*
 * Copyright (C) 2022-2025 Yubico.
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

import '../../core/state.dart';
import '../../desktop/models.dart';
import '../../desktop/state.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../management/models.dart';
import '../state.dart';
import 'elevate_fido_buttons.dart';
import 'message_page.dart';

class AppFailurePage extends ConsumerWidget {
  final Object cause;
  const AppFailurePage({required this.cause, super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reason = cause;

    Widget? graphic = Icon(Symbols.error,
        size: 96, color: Theme.of(context).colorScheme.error);
    String? header = l10n.l_error_occurred;
    String? message = reason.toString();
    String? title;
    bool centered = true;
    List<Capability>? capabilities;
    List<Widget> actions = [];
    String? footnote;

    if (reason is RpcError) {
      if (reason.status == 'connection-error') {
        switch (reason.body['connection']) {
          case 'ccid':
            header = l10n.l_ccid_connection_failed;
            if (Platform.isMacOS) {
              message = l10n.p_try_reinsert_yk;
            } else if (Platform.isLinux) {
              message = l10n.p_pcscd_unavailable;
            } else {
              message = l10n.p_ccid_service_unavailable;
            }
            break;
          case 'fido':
            if (Platform.isWindows &&
                !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
              final currentSection = ref.read(currentSectionProvider);
              title = currentSection.getDisplayName(l10n);
              capabilities = currentSection.capabilities;
              header = l10n.l_admin_privileges_required;
              message = l10n.p_webauthn_elevated_permissions_required;
              centered = false;
              graphic = null;
              actions = [
                const ElevateFidoButtons(),
              ];
              if (isMicrosoftStore) {
                footnote = l10n.l_ms_store_permission_note;
              }
            }
            break;
          default:
            header = l10n.l_open_connection_failed;
            message = l10n.p_try_reinsert_yk;
        }
      }
    }

    return MessagePage(
      centered: centered,
      title: title,
      capabilities: capabilities,
      graphic: graphic,
      header: header,
      message: message,
      footnote: footnote,
      actionsBuilder: (context, expanded) => actions,
    );
  }
}
