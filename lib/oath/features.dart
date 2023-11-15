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

final actions = oath.feature('actions');

final actionsAdd = actions.feature('add');
final actionsIcons = actions.feature('icons');
final actionsPassword = actions.feature('password');
final actionsReset = actions.feature('reset');

final accounts = actions.feature('accounts');

final accountsClipboard = accounts.feature('clipboard');
final accountsPin = accounts.feature('pin');
final accountsRename = accounts.feature('rename');
final accountsDelete = accounts.feature('delete');
