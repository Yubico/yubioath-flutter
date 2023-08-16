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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/message.dart';
import '../../oath/keys.dart';
import '../../oath/models.dart';
import '../../oath/views/add_account_page.dart';
import '../../oath/views/add_multi_account_page.dart';

const _appLinkMethodsChannel = MethodChannel('app.link.methods');

void setupOtpAuthLinkHandler(BuildContext context) {
  _appLinkMethodsChannel.setMethodCallHandler((call) async {
    final args = jsonDecode(call.arguments);
    switch (call.method) {
      case 'handleOtpAuthLink':
        {
          final l10n = AppLocalizations.of(context)!;
          Navigator.popUntil(context, ModalRoute.withName('/'));
          var uri = args['link'];

          List<CredentialData> creds =
              uri != null ? CredentialData.fromUri(Uri.parse(uri)) : [];

          if (creds.isEmpty) {
            showMessage(context, l10n.l_qr_not_found);
          } else if (creds.length == 1) {
            await showBlurDialog(
              context: context,
              builder: (context) => OathAddAccountPage(
                null,
                null,
                credentials: null,
                credentialData: creds[0],
              ),
            );
          } else {
            await showBlurDialog(
              context: context,
              builder: (context) => OathAddMultiAccountPage(null, null, creds,
                  key: migrateAccountAction),
            );
          }
          break;
        }
      default:
        throw PlatformException(
          code: 'NotImplemented',
          message: 'Method ${call.method} is not implemented',
        );
    }
  });
}
