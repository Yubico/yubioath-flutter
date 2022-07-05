import 'package:flutter/material.dart';

final Image noAccounts = _graphic('no-accounts');
final Image noFingerprints = _graphic('no-fingerprints');
final Image noPermission = _graphic('no-permission');
final Image manageAccounts = _graphic('manage-accounts');

Image _graphic(String name) => Image.asset('assets/graphics/$name.png');
