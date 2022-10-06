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

import '../../app/message.dart';
import '../../oath/models.dart';
import '../../oath/views/add_account_page.dart';

const _appLinkMethodsChannel = MethodChannel('app.link.methods');

void setupOtpAuthLinkHandler(BuildContext context) {
  _appLinkMethodsChannel.setMethodCallHandler((call) async {
    final args = jsonDecode(call.arguments);
    switch (call.method) {
      case 'handleOtpAuthLink':
        {
          var url = args['link'];
          var otpauth = CredentialData.fromUri(Uri.parse(url));
          Navigator.popUntil(context, ModalRoute.withName('/'));
          await showBlurDialog(
            context: context,
            routeSettings: const RouteSettings(name: 'oath_add_account'),
            builder: (_) {
              return OathAddAccountPage(
                null,
                null,
                credentials: null,
                credentialData: otpauth,
              );
            },
          );
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
