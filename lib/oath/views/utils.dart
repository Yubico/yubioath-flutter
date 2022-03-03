import 'dart:math';

import '../models.dart';
import '../../core/models.dart';

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
