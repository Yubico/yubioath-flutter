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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/models.dart';
import '../../desktop/state.dart';
import '../message.dart';
import '../models.dart';
import '../state.dart';
import 'device_avatar.dart';
import 'graphics.dart';
import 'message_page.dart';

class DeviceErrorScreen extends ConsumerWidget {
  final DeviceNode node;
  final Object? error;
  const DeviceErrorScreen(this.node, {this.error, super.key});

  Widget _buildUsbPid(BuildContext context, WidgetRef ref, UsbPid pid) {
    final l10n = AppLocalizations.of(context)!;
    if (pid.usbInterfaces == UsbInterface.fido.value) {
      if (Platform.isWindows &&
          !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
        return MessagePage(
          graphic: noPermission,
          message: l10n.p_elevated_permissions_required,
          actions: [
            ElevatedButton.icon(
              label: Text(l10n.w_unlock),
              icon: const Icon(Icons.lock_open),
              onPressed: () async {
                final closeMessage = showMessage(
                    context, l10n.l_elevating_permissions,
                    duration: const Duration(seconds: 30));
                try {
                  if (await ref.read(rpcProvider).requireValue.elevate()) {
                    ref.invalidate(rpcProvider);
                  } else {
                    await ref.read(withContextProvider)((context) async =>
                        showMessage(context, l10n.l_permission_denied));
                  }
                } finally {
                  closeMessage();
                }
              },
            ),
          ],
        );
      }
    }
    return MessagePage(
      graphic: const DeviceAvatar(child: Icon(Icons.usb_off)),
      message: l10n.l_yk_no_access,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return node.map(
      usbYubiKey: (node) => _buildUsbPid(context, ref, node.pid),
      nfcReader: (node) {
        final String message;
        switch (error) {
          case 'unknown-device':
            message = l10n.l_unknown_device;
            break;
          default:
            message = l10n.l_place_on_nfc_reader;
        }
        return MessagePage(message: message);
      },
    );
  }
}
