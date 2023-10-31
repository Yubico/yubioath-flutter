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
const _keyAction = '$_prefix.actions';
const _accountAction = '$_prefix.account.actions';

// This is global so we can access it from the global Ctrl+F shortcut.
final searchAccountsField = GlobalKey();

// Key actions
const setOrManagePasswordAction =
    Key('$_keyAction.action.set_or_manage_password');
const addAccountAction = Key('$_keyAction.add_account');
const migrateAccountAction = Key('$_keyAction.migrate_account');
const resetAction = Key('$_keyAction.reset');
const resetButton = Key('$_keyAction.reset_button');
const customIconsAction = Key('$_keyAction.custom_icons');
const addAccountManuallyButton = Key('$_keyAction.add_account_manually');

// Credential actions
const copyAction = Key('$_accountAction.copy');
const calculateAction = Key('$_accountAction.calculate');
const togglePinAction = Key('$_accountAction.toggle_pin');
const editAction = Key('$_accountAction.edit');
const deleteAction = Key('$_accountAction.delete');

const noAccountsView = Key('$_prefix.no_accounts');

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

// Filter Chips
const requireTouchFilterChip = Key('$_prefix.require_touch_filter_chip');
const oathTypeFilterChip = Key('$_prefix.oath_type_filter_chip');
const oathTypeTotpFilterValue = Key('$_prefix.oath_type_totp_filter_value');
const oathTypeHotpFilterValue = Key('$_prefix.oath_type_hotp_filter_value');
const hashAlgorithmFilterChip = Key('$_prefix.hash_algorithm_filter_chip');
const hashAlgorithmSha1FilterValue =
    Key('$_prefix.hash_algorithm_sha1_filter_value');
const hashAlgorithmSha256FilterValue =
    Key('$_prefix.hash_algorithm_sha256_filter_value');
const hashAlgorithmSha512FilterValue =
    Key('$_prefix.hash_algorithm_sha512_filter_value');
