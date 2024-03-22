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
const pinLockManagementKeyChip = Key('$_keyAction.pinlock_managementkey');
const setupMacOsAction = Key('$_keyAction.setup_macos');

// Slot actions
const generateAction = Key('$_slotAction.generate');
const importAction = Key('$_slotAction.import');
const exportAction = Key('$_slotAction.export');
const deleteAction = Key('$_slotAction.delete');
const moveAction = Key('$_slotAction.move');

const saveButton = Key('$_prefix.save');
const deleteButton = Key('$_prefix.delete');
const unlockButton = Key('$_prefix.unlock');
const resetButton = Key('$_prefix.reset');

const managementKeyField = Key('$_prefix.management_key');
const managementKeyRefresh = Key('$_prefix.management_key_refresh');

const pinPukField = Key('$_prefix.pin_puk');
const newPinPukField = Key('$_prefix.new_pin_puk');
const confirmPinPukField = Key('$_prefix.confirm_pin_puk');
const subjectField = Key('$_prefix.subject');

const meatballButton9a = Key('$_prefix.9a.meatball.button');
const meatballButton9c = Key('$_prefix.9c.meatball.button');
const meatballButton9d = Key('$_prefix.9d.meatball.button');
const meatballButton9e = Key('$_prefix.9e.meatball.button');
const meatballButton82 = Key('$_prefix.82.meatball.button');
const meatballButton83 = Key('$_prefix.83.meatball.button');
const meatballButton84 = Key('$_prefix.84.meatball.button');
const meatballButton85 = Key('$_prefix.85.meatball.button');
const meatballButton86 = Key('$_prefix.86.meatball.button');
const meatballButton87 = Key('$_prefix.87.meatball.button');
const meatballButton88 = Key('$_prefix.88.meatball.button');
const meatballButton89 = Key('$_prefix.89.meatball.button');
const meatballButton8a = Key('$_prefix.8a.meatball.button');
const meatballButton8b = Key('$_prefix.8b.meatball.button');
const meatballButton8c = Key('$_prefix.8c.meatball.button');
const meatballButton8d = Key('$_prefix.8d.meatball.button');
const meatballButton8e = Key('$_prefix.8e.meatball.button');
const meatballButton8f = Key('$_prefix.8f.meatball.button');
const meatballButton90 = Key('$_prefix.90.meatball.button');
const meatballButton91 = Key('$_prefix.91.meatball.button');
const meatballButton92 = Key('$_prefix.92.meatball.button');
const meatballButton93 = Key('$_prefix.93.meatball.button');
const meatballButton94 = Key('$_prefix.94.meatball.button');
const meatballButton95 = Key('$_prefix.95.meatball.button');

const appListItem9a = Key('$_prefix.9a.applistitem');
const appListItem9c = Key('$_prefix.9c.applistitem');
const appListItem9d = Key('$_prefix.9d.applistitem');
const appListItem9e = Key('$_prefix.9e.applistitem');
const appListItem82 = Key('$_prefix.82.applistitem');
const appListItem83 = Key('$_prefix.83.applistitem');
const appListItem84 = Key('$_prefix.84.applistitem');
const appListItem85 = Key('$_prefix.85.applistitem');
const appListItem86 = Key('$_prefix.86.applistitem');
const appListItem87 = Key('$_prefix.87.applistitem');
const appListItem88 = Key('$_prefix.88.applistitem');
const appListItem89 = Key('$_prefix.89.applistitem');
const appListItem8a = Key('$_prefix.8a.applistitem');
const appListItem8b = Key('$_prefix.8b.applistitem');
const appListItem8c = Key('$_prefix.8c.applistitem');
const appListItem8d = Key('$_prefix.8d.applistitem');
const appListItem8e = Key('$_prefix.8e.applistitem');
const appListItem8f = Key('$_prefix.8f.applistitem');
const appListItem90 = Key('$_prefix.90.applistitem');
const appListItem91 = Key('$_prefix.91.applistitem');
const appListItem92 = Key('$_prefix.92.applistitem');
const appListItem93 = Key('$_prefix.93.applistitem');
const appListItem94 = Key('$_prefix.94.applistitem');
const appListItem95 = Key('$_prefix.95.applistitem');

// SlotMetadata body keys
const slotMetadataKeyType = Key('$_prefix.slotMetadata.keyType');

// CertInfo body keys
const certInfoKeyType = Key('$_prefix.certInfo.keyType');
const certInfoSubject = Key('$_prefix.certInfo.subject');
const certInfoIssuer = Key('$_prefix.certInfo.issuer');
const certInfoSerial = Key('$_prefix.certInfo.serial');
const certInfoFingerprint = Key('$_prefix.certInfo.fingerprint');
const certInfoValidFrom = Key('$_prefix.certInfo.validFrom');
const certInfoValidTo = Key('$_prefix.certInfo.validTo');
