import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../../core/models.dart';
import '../state.dart';

/// Calculates the available space for issuer and account name.
///
/// Returns a [Pair] of the space available for the issuer and account name,
/// respectively, based on the current state of the credential.
Pair<int, int> getRemainingKeySpace(
    {required OathType oathType,
    required int period,
    required String issuer,
    required String name}) {
  int remaining = 64; // The field is 64 bytes in total.

  if (oathType == OathType.totp && period != defaultPeriod) {
    // Non-standard TOTP periods are stored as part of this data, as a "D/"- prefix.
    remaining -= '$period/'.length;
  }
  int issuerSpace = issuer.length;
  if (issuer.isNotEmpty) {
    // Issuer is separated from name with a ":", if present.
    issuerSpace += 1;
  }

  return Pair(
    // Always reserve at least one character for name
    remaining - 1 - max(name.length, 1),
    remaining - issuerSpace,
  );
}

/// Formats an OATH code for display.
///
/// If the [OathCode] is null, then a placeholder string is returned.
String formatOathCode(OathCode? code) {
  var value = code?.value;
  if (value == null) {
    return '••• •••';
  } else if (value.length < 6) {
    return value;
  } else {
    var i = value.length ~/ 2;
    return value.substring(0, i) + ' ' + value.substring(i);
  }
}

/// Calculates a new OATH code for a credential.
///
/// This function will take care of prompting the user for touch if needed.
Future<OathCode> calculateCode(BuildContext context, OathCredential credential,
    OathCredentialListNotifier notifier) async {
  Function? close;
  if (credential.touchRequired) {
    close = ScaffoldMessenger.of(context)
        .showSnackBar(
          const SnackBar(
            content: Text('Touch your YubiKey'),
            duration: Duration(seconds: 30),
          ),
        )
        .close;
  } else if (credential.oathType == OathType.hotp) {
    final showPrompt = Timer(const Duration(milliseconds: 500), () {
      close = ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
              content: Text('Touch your YubiKey'),
              duration: Duration(seconds: 30),
            ),
          )
          .close;
    });
    close = showPrompt.cancel;
  }
  try {
    return await notifier.calculate(credential);
  } finally {
    // Hide the touch prompt when done
    close?.call();
  }
}
