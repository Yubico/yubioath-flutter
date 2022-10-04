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
