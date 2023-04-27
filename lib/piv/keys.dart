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

const managePinAction = Key('$_prefix.manage_pin');
const managePukAction = Key('$_prefix.manage_puk');
const manageManagementKeyAction = Key('$_prefix.manage_management_key');
const resetAction = Key('$_prefix.reset');

const setupMacOsAction = Key('$_prefix.setup_macos');
const saveButton = Key('$_prefix.save');
const deleteButton = Key('$_prefix.delete');
const unlockButton = Key('$_prefix.unlock');

const managementKeyField = Key('$_prefix.management_key');
const pinPukField = Key('$_prefix.pin_puk');
const newPinPukField = Key('$_prefix.new_pin_puk');
const confirmPinPukField = Key('$_prefix.confirm_pin_puk');
const subjectField = Key('$_prefix.subject');
