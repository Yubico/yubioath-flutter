/*
 * Copyright (C) 2022-2023 Yubico.
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

import '../../android/app_methods.dart';
import '../../android/oath/state.dart';
import '../../android/qr_scanner/qr_scanner_provider.dart';
import '../../android/state.dart';
import '../../core/state.dart';
import '../../exception/cancellation_exception.dart';
import '../../fido/views/fingerprints_screen.dart';
import '../../fido/views/passkeys_screen.dart';
import '../../fido/views/webauthn_page.dart';
import '../../management/views/management_screen.dart';
import '../../oath/views/oath_screen.dart';
import '../../otp/views/otp_screen.dart';
import '../../piv/views/piv_screen.dart';
import '../../widgets/custom_icons.dart';
import '../message.dart';
import '../models.dart';
import '../state.dart';
import 'device_error_screen.dart';
import 'message_page.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<Function(BuildContext)?>(
      contextConsumer,
      (previous, next) {
        next?.call(context);
      },
    );

    if (isAndroid) {
      isNfcEnabled().then((value) =>
          ref.read(androidNfcStateProvider.notifier).setNfcEnabled(value));
    }

    // If the current device changes, we need to pop any open dialogs.
    ref.listen<AsyncValue<YubiKeyData>>(currentDeviceDataProvider, (_, __) {
      Navigator.of(context).popUntil((route) {
        return route.isFirst ||
            [
              'device_picker',
              'settings',
              'about',
              'licenses',
              'user_interaction_prompt',
              'oath_add_account',
              'oath_icon_pack_dialog',
              'android_qr_scanner_view',
            ].contains(route.settings.name);
      });
    });

    final deviceNode = ref.watch(currentDeviceProvider);
    final noKeyImage = Image.asset(
      'assets/graphics/no-key.png',
      filterQuality: FilterQuality.medium,
      scale: 2,
      color: Theme.of(context).colorScheme.primary,
    );
    if (deviceNode == null) {
      if (isAndroid) {
        var hasNfcSupport = ref.watch(androidNfcSupportProvider);
        var isNfcEnabled = ref.watch(androidNfcStateProvider);
        return MessagePage(
          centered: true,
          graphic: noKeyImage,
          header: hasNfcSupport && isNfcEnabled
              ? l10n.l_insert_or_tap_yk
              : l10n.l_insert_yk,
          actionsBuilder: (context, expanded) => [
            if (hasNfcSupport && !isNfcEnabled)
              ElevatedButton.icon(
                  label: Text(l10n.s_enable_nfc),
                  icon: nfcIcon,
                  onPressed: () async {
                    await openNfcSettings();
                  })
          ],
          actionButtonBuilder: (context) => IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: l10n.s_add_account,
            onPressed: () async {
              ref.read(androidAddAccountFlowProvider)(context);
            },
          ),
        );
      } else {
        return MessagePage(
          centered: true,
          delayedContent: false,
          graphic: noKeyImage,
          header: l10n.l_insert_yk,
        );
      }
    } else {
      return ref.watch(currentDeviceDataProvider).when(
            data: (data) {
              final app = ref.watch(currentAppProvider);
              final capabilities = app.getCapabilities();
              if (data.info.supportedCapabilities.isEmpty &&
                  data.name == 'Unrecognized device') {
                return MessagePage(
                  centered: true,
                  graphic: Icon(
                    Icons.help_outlined,
                    size: 96,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  header: l10n.s_yk_not_recognized,
                );
              } else if (app.getAvailability(data) ==
                  Availability.unsupported) {
                return MessagePage(
                  title: app.getDisplayName(l10n),
                  capabilities: capabilities,
                  header: l10n.s_app_not_supported,
                  message: l10n.l_app_not_supported_on_yk(capabilities
                      .map((c) => c.getDisplayName(l10n))
                      .join(',')),
                );
              } else if (app.getAvailability(data) != Availability.enabled) {
                return MessagePage(
                  title: app.getDisplayName(l10n),
                  capabilities: capabilities,
                  header: l10n.s_app_disabled,
                  message: l10n.l_app_disabled_desc(capabilities
                      .map((c) => c.getDisplayName(l10n))
                      .join(',')),
                  actionsBuilder: (context, expanded) => [
                    ActionChip(
                      label: Text(data.info.version.major > 4
                          ? l10n.s_toggle_applications
                          : l10n.s_toggle_interfaces),
                      onPressed: () async {
                        await showBlurDialog(
                          context: context,
                          builder: (context) => ManagementScreen(data),
                        );
                      },
                      avatar: const Icon(Icons.construction),
                    )
                  ],
                );
              }

              return switch (app) {
                Application.accounts => OathScreen(data.node.path),
                Application.webauthn => const WebAuthnScreen(),
                Application.passkeys => PasskeysScreen(data),
                Application.fingerprints => FingerprintsScreen(data),
                Application.certificates => PivScreen(data.node.path),
                Application.slots => OtpScreen(data.node.path),
                _ => MessagePage(
                    header: l10n.s_app_not_supported,
                    message: l10n.l_app_not_supported_desc,
                  ),
              };
            },
            loading: () => DeviceErrorScreen(deviceNode),
            error: (error, _) => DeviceErrorScreen(deviceNode, error: error),
          );
    }
  }
}
