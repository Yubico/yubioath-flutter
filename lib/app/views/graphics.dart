import 'package:flutter/material.dart';

final Image noAccounts = _graphic('no-accounts');
final Image noDiscoverable = _graphic('no-discoverable');
final Image noFingerprints = _graphic('no-fingerprints');
final Image noPermission = _graphic('no-permission');

Image _graphic(String name) => Image.asset('assets/graphics/$name.png');
