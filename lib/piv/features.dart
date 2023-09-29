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

import '../app/features.dart';

final actions = piv.feature('actions');

final actionsPin = actions.feature('pin');
final actionsPuk = actions.feature('puk');
final actionsManagementKey = actions.feature('managementKey', enabled: false);
final actionsReset = actions.feature('reset', enabled: false);

final slots = piv.feature('slots');

final slotsGenerate = slots.feature('generate', enabled: false);
final slotsImport = slots.feature('import', enabled: false);
final slotsExport = slots.feature('export');
final slotsDelete = slots.feature('delete', enabled: false);
