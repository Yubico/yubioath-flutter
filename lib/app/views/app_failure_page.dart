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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desktop/models.dart';
import '../../desktop/state.dart';
import '../message.dart';
import '../state.dart';
import 'graphics.dart';
import 'message_page.dart';

class AppFailurePage extends ConsumerWidget {
  final Widget? title;
  final Object cause;
  const AppFailurePage({this.title, required this.cause, super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = cause;

    Widget? graphic = const Icon(Icons.error);
    String? header = 'An error has occured';
    String? message = reason.toString();
    List<Widget> actions = [];

    if (reason is RpcError) {
      if (reason.status == 'connection-error') {
        switch (reason.body['connection']) {
          case 'ccid':
            header = 'Failed to open smart card connection';
            if (Platform.isMacOS) {
              message = 'Try to remove and re-insert your YubiKey.';
            } else if (Platform.isLinux) {
              message = 'Make sure pcscd is installed and running.';
            } else {
              message = 'Make sure your smart card service is functioning.';
            }
            break;
          case 'fido':
            if (Platform.isWindows &&
                !ref.watch(rpcStateProvider.select((state) => state.isAdmin))) {
              graphic = noPermission;
              header = null;
              message = AppLocalizations.of(context)!.appFailurePage_txt_info;
              actions = [
                ElevatedButton.icon(
                  label: Text(
                      AppLocalizations.of(context)!.appFailurePage_btn_unlock),
                  icon: const Icon(Icons.lock_open),
                  onPressed: () async {
                    final closeMessage = showMessage(
                        context,
                        AppLocalizations.of(context)!
                            .appFailurePage_msg_permission,
                        duration: const Duration(seconds: 30));
                    try {
                      if (await ref.read(rpcProvider).requireValue.elevate()) {
                        ref.invalidate(rpcProvider);
                      } else {
                        await ref.read(withContextProvider)(
                          (context) async {
                            showMessage(context, 'Permission denied');
                          },
                        );
                      }
                    } finally {
                      closeMessage();
                    }
                  },
                ),
              ];
            }
            break;
          default:
            header = 'Failed to open connection';
            message = 'Try to remove and re-insert your YubiKey.';
        }
      }
    }

    return MessagePage(
      title: title,
      graphic: graphic,
      header: header,
      message: message,
      actions: actions,
    );
  }
}
