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

import 'dart:math';

import '../../widgets/utf8_utils.dart';
import '../../core/models.dart';
import '../models.dart';

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
  int issuerSpace = byteLength(issuer);
  if (issuer.isNotEmpty) {
    // Issuer is separated from name with a ":", if present.
    issuerSpace += 1;
  }

  return Pair(
    // Always reserve at least one character for name
    remaining - 1 - max(byteLength(name), 1),
    remaining - issuerSpace,
  );
}

/// Gets a textual name for the account, based on the issuer and name.
String getTextName(OathCredential credential) {
  return credential.issuer != null
      ? '${credential.issuer} (${credential.name})'
      : credential.name;
}
