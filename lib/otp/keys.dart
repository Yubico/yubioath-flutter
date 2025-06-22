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

import 'models.dart';

const _prefix = 'otp.keys';
const _keyAction = '$_prefix.actions';
const _slotAction = '$_prefix.slot.actions';

// Key actions
const swapSlots = Key('$_keyAction.swap_slots');

// Slot actions
const configureYubiOtp = Key('$_slotAction.configure_yubiotp');
const configureHotp = Key('$_slotAction.configure_hotp');
const configureStatic = Key('$_slotAction.configure_static');
const configureChalResp = Key('$_slotAction.configure_chal_resp');
const deleteAction = Key('$_slotAction.delete');

const saveButton = Key('$_prefix.save');
const deleteButton = Key('$_prefix.delete');
const swapButton = Key('$_prefix.swap');
const overwriteButton = Key('$_prefix.overwrite');

const secretField = Key('$_prefix.secret');
const publicIdField = Key('$_prefix.public_id');
const privateIdField = Key('$_prefix.private_id');

const useSerial = Key('$_prefix.use_serial');
const generatePrivateId = Key('$_prefix.generate_private_id');
const generateSecretKey = Key('$_prefix.generate_secret_key');

Key getOpenMenuButtonKey(SlotId slotId) =>
    Key('$_prefix.open_slot_menu_slot_${slotId.name}');

Key getAppListItemKey(SlotId slotId) =>
    Key('$_prefix.app_list_item_slot_${slotId.name}');
