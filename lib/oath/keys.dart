/*
 * Copyright (C) 2022-2023 Yubico.
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

import 'package:flutter/material.dart';

const _prefix = 'oath.keys';

const setOrManagePasswordAction = Key('$_prefix.set_or_manage_w_password');
const addAccountAction = Key('$_prefix.add_account');
const resetAction = Key('$_prefix.reset');

const customIconsAction = Key('$_prefix.custom_icons');

const noAccountsView = Key('$_prefix.no_accounts');

// This is global so we can access it from the global Ctrl+F shortcut.
final searchAccountsField = GlobalKey();

const passwordField = Key('$_prefix.password');
const currentPasswordField = Key('$_prefix.current_password');
const newPasswordField = Key('$_prefix.new_password');
const confirmPasswordField = Key('$_prefix.confirm_password');
const issuerField = Key('$_prefix.issuer');
const nameField = Key('$_prefix.name');
const secretField = Key('$_prefix.secret');

const unlockButton = Key('$_prefix.unlock');
const saveButton = Key('$_prefix.save');
const deleteButton = Key('$_prefix.delete');
const savePasswordButton = Key('$_prefix.save_password');
const removePasswordButton = Key('$_prefix.remove_password');
