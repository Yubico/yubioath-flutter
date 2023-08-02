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

const _prefix = 'piv.keys';
const _keyAction = '$_prefix.actions';
const _slotAction = '$_prefix.slot.actions';

// Key actions
const managePinAction = Key('$_keyAction.manage_pin');
const managePukAction = Key('$_keyAction.manage_puk');
const manageManagementKeyAction = Key('$_keyAction.manage_management_key');
const resetAction = Key('$_keyAction.reset');
const setupMacOsAction = Key('$_keyAction.setup_macos');

// Slot actions
const generateAction = Key('$_slotAction.generate');
const importAction = Key('$_slotAction.import');
const exportAction = Key('$_slotAction.export');
const deleteAction = Key('$_slotAction.delete');

const saveButton = Key('$_prefix.save');
const deleteButton = Key('$_prefix.delete');
const unlockButton = Key('$_prefix.unlock');

const managementKeyField = Key('$_prefix.management_key');
const pinPukField = Key('$_prefix.pin_puk');
const newPinPukField = Key('$_prefix.new_pin_puk');
const confirmPinPukField = Key('$_prefix.confirm_pin_puk');
const subjectField = Key('$_prefix.subject');
