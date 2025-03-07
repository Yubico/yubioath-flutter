/*
 * Copyright (C) 2023 Yubico.
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

import '../core/state.dart';

final home = root.feature('home');
final oath = root.feature('oath');
final fido = root.feature('fido');
final piv = root.feature('piv');
final otp = root.feature('otp');

final management = root.feature('management');

final fingerprints = fido.feature('fingerprints');
