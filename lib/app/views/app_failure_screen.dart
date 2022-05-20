import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yubico_authenticator/desktop/models.dart';

class AppFailureScreen extends StatelessWidget {
  final Object reason;
  const AppFailureScreen(this.reason, {super.key}) : super();

  @override
  Widget build(BuildContext context) {
    final cause = reason;
    if (cause is RpcError) {
      if (cause.status == 'connection-error' &&
          cause.body['connection'] == 'ccid') {
        var msg = 'Failed to open smart card connection';
        if (Platform.isMacOS) {
          msg += '\nTry to remove and re-insert your YubiKey to regain access.';
        } else if (Platform.isLinux) {
          msg += '\nMake sure pcscd is running.';
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                msg,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            cause.toString(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
