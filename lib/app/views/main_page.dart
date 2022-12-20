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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cancellation_exception.dart';
import '../../core/state.dart';
import '../../fido/views/fido_screen.dart';
import '../../oath/models.dart';
import '../../oath/views/add_account_page.dart';
import '../../oath/views/oath_screen.dart';
import '../message.dart';
import '../models.dart';
import '../state.dart';
import 'device_error_screen.dart';
import 'message_page.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Function(BuildContext)?>(
      contextConsumer,
      (previous, next) {
        next?.call(context);
      },
    );

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
            ].contains(route.settings.name);
      });
    });

    final deviceNode = ref.watch(currentDeviceProvider);
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final noKeyImage = Image.asset(
      isDarkTheme
          ? 'assets/graphics/no-key_dark.png'
          : 'assets/graphics/no-key.png',
      filterQuality: FilterQuality.medium,
      scale: 2,
    );
    if (deviceNode == null) {
      if (isAndroid) {
        return MessagePage(
          graphic: noKeyImage,
          message: 'Insert or tap your YubiKey',
          actionButtonBuilder: (keyActions) => IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add account',
            onPressed: () async {
              CredentialData? otpauth;
              final scanner = ref.read(qrScannerProvider);
              if (scanner != null) {
                try {
                  final url = await scanner.scanQr();
                  if (url != null) {
                    otpauth = CredentialData.fromUri(Uri.parse(url));
                  }
                } on CancellationException catch (_) {
                  // ignored - user cancelled
                  return;
                }
              }
              await showBlurDialog(
                context: context,
                routeSettings: const RouteSettings(name: 'oath_add_account'),
                builder: (context) {
                  return OathAddAccountPage(
                    null,
                    null,
                    credentials: null,
                    credentialData: otpauth,
                  );
                },
              );
            },
          ),
        );
      } else {
        return MessagePage(
          graphic: noKeyImage,
          message: 'Insert your YubiKey',
        );
      }
    } else {
      return ref.watch(currentDeviceDataProvider).when(
            data: (data) {
              final app = ref.watch(currentAppProvider);
              if (app.getAvailability(data) == Availability.unsupported) {
                return MessagePage(
                  header: 'Application not supported',
                  message:
                      'The used YubiKey does not support \'${app.name}\' application',
                );
              } else if (app.getAvailability(data) != Availability.enabled) {
                return MessagePage(
                  header: 'Application disabled',
                  message:
                      'Enable the \'${app.name}\' application on your YubiKey to access',
                );
              }

              switch (app) {
                case Application.oath:
                  return OathScreen(data.node.path);
                case Application.fido:
                  return FidoScreen(data);
                default:
                  return const MessagePage(
                    header: 'Not supported',
                    message: 'This application is not supported',
                  );
              }
            },
            loading: () => DeviceErrorScreen(deviceNode),
            error: (error, _) => DeviceErrorScreen(deviceNode, error: error),
          );
    }
  }
}
