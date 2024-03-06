/*
 * Copyright (C) 2022 Yubico.
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

// global keys
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();

const _prefix = 'app.keys';
const deviceInfoListTile = Key('$_prefix.device_info_list_tile');
const noDeviceAvatar = Key('$_prefix.no_device_avatar');
const actionsIconButtonKey = Key('$_prefix.actions_icon_button');

// drawer items
const homeDrawer = Key('$_prefix.drawer.home');
const managementAppDrawer = Key('$_prefix.drawer.management');
const oathAppDrawer = Key('$_prefix.drawer.oath');
const u2fAppDrawer = Key('$_prefix.drawer.fido.webauthn');
const fidoPasskeysAppDrawer = Key('$_prefix.drawer.fido.passkeys');
const fidoFingerprintsAppDrawer = Key('$_prefix.drawer.fido.fingerprints');
const otpAppDrawer = Key('$_prefix.drawer.otp');
const pivAppDrawer = Key('$_prefix.drawer.piv');
const hsmauthAppDrawer = Key('$_prefix.drawer.hsmauth');
const openpgpAppDrawer = Key('$_prefix.drawer.openpgp');

// drawer yubikey more items
const yubikeyPopupMenuButton = Key('$_prefix.yubikey_popup_menu_button');
const yubikeyLabelColorMenuButton =
    Key('$_prefix.yubikey_label_color_menu_button');
const yubikeyApplicationToggleMenuButton =
    Key('$_prefix.yubikey_application_toggle_menu_button');
const yubikeyFactoryResetMenuButton =
    Key('$_prefix.yubikey_factory_reset_menu_button');

// factory reset dialog
const factoryResetPickResetOath = Key('$_prefix.yubikey_factory_reset_oath');
const factoryResetPickResetFido2 = Key('$_prefix.yubikey_factory_reset_fido2');
const factoryResetPickResetPiv = Key('$_prefix.yubikey_factory_reset_piv');
const factoryResetCancel = Key('$_prefix.yubikey_factory_reset_cancel');
const factoryResetReset = Key('$_prefix.yubikey_factory_reset_reset');

// settings page
const settingDrawerIcon = Key('$_prefix.settings_drawer_icon');
const helpDrawerIcon = Key('$_prefix.setting_drawer_icon');
const themeModeSetting = Key('$_prefix.settings.theme_mode');
Key themeModeOption(ThemeMode mode) => Key('$_prefix.theme_mode.${mode.name}');
const tosButton = Key('$_prefix.tos_button');
const privacyButton = Key('$_prefix.privacy_button');
const licensesButton = Key('$_prefix.licenses_button');
const feedbackButton = Key('$_prefix.feedback_button');
const helpButton = Key('$_prefix.help_button');
const diagnosticsChip = Key('$_prefix.diagnostics_chip');
const logChip = Key('$_prefix.log_chip');
const screenshotChip = Key('$_prefix.screenshot_chip');

// misc buttons
const closeButton = Key('$_prefix.close_button');
