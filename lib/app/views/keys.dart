import 'package:flutter/material.dart';

// global keys
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();

const _prefix = 'app.keys';
const deviceInfoListTile = Key('$_prefix.device_info_list_tile');
const noDeviceAvatar = Key('$_prefix.no_device_avatar');

// drawer items
const managementAppDrawer = Key('$_prefix.drawer.management');
