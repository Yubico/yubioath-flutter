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
const managementAppDrawer = Key('$_prefix.drawer.management');
