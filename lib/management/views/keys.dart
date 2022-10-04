import 'package:flutter/material.dart';

const _prefix = 'management.keys';

// used to build Keys
const _capabilityKeyPrefix = '$_prefix.capability';
const usbCapabilityKeyPrefix = '$_capabilityKeyPrefix.usb';
const nfcCapabilityKeyPrefix = '$_capabilityKeyPrefix.nfc';

const screenKey = Key('$_prefix.screen.management');
const saveButtonKey = Key('$_prefix.management.btn.save');
