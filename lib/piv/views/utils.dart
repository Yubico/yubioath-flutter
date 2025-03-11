/*
 * Copyright (C) 2024 Yubico.
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

import '../../core/models.dart';
import '../models.dart';

List<KeyType> getSupportedKeyTypes(Version version, bool isFips) => [
  if (!isFips) KeyType.rsa1024,
  KeyType.rsa2048,
  if (version.isAtLeast(5, 7)) ...[
    KeyType.rsa3072,
    KeyType.rsa4096,
    KeyType.ed25519,
    if (!isFips) KeyType.x25519,
  ],
  KeyType.eccp256,
  if (version.isAtLeast(4, 0)) ...[KeyType.eccp384],
];

PinPolicy getPinPolicy(SlotId slot, bool match) {
  if (match) {
    if (slot == SlotId.signature) {
      return PinPolicy.matchAlways;
    }
    return PinPolicy.matchOnce;
  }
  return PinPolicy.dfault;
}
