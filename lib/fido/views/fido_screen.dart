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

import '../../app/models.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_page.dart';
import '../../app/views/graphics.dart';
import '../../app/views/message_page.dart';
import '../../management/models.dart';
import '../state.dart';
import 'locked_page.dart';
import 'unlocked_page.dart';

class FidoScreen extends ConsumerWidget {
  final YubiKeyData deviceData;
  const FidoScreen(this.deviceData, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(fidoStateProvider(deviceData.node.path)).when(
        loading: () => AppPage(
              title: Text(l10n.w_webauthn),
              centered: true,
              delayedContent: true,
              child: const CircularProgressIndicator(),
            ),
        error: (error, _) {
          final supported = deviceData
                  .info.supportedCapabilities[deviceData.node.transport] ??
              0;
          if (Capability.fido2.value & supported == 0) {
            return MessagePage(
              title: Text(l10n.w_webauthn),
              graphic: manageAccounts,
              header: l10n.l_ready_to_use,
              message: l10n.l_register_sk_on_websites,
            );
          }
          final enabled = deviceData
                  .info.config.enabledCapabilities[deviceData.node.transport] ??
              0;
          if (Capability.fido2.value & enabled == 0) {
            return MessagePage(
              title: Text(l10n.w_webauthn),
              header: l10n.l_fido_disabled,
              message: l10n.l_webauthn_req_fido2,
            );
          }

          return AppFailurePage(
            title: Text(l10n.w_webauthn),
            cause: error,
          );
        },
        data: (fidoState) {
          return fidoState.unlocked
              ? FidoUnlockedPage(deviceData.node, fidoState)
              : FidoLockedPage(deviceData.node, fidoState);
        });
  }
}
