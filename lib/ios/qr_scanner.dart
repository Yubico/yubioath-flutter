/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import 'dart:convert';

import 'package:flutter/services.dart';

import '../app/state.dart';
import '../exception/cancellation_exception.dart';
import '../generated/l10n/app_localizations.dart';

class IosQrScanner implements QrScanner {
  static const channel = MethodChannel('com.yubico.authenticator/qr');
  final WithContext _withContext;

  IosQrScanner(this._withContext);

  @override
  Future<String?> scanQr([String? imageData]) async {
    if (imageData != null) {
      return channel.invokeMethod<String>('scanImage', base64Decode(imageData));
    }
    return _withContext((context) async {
      final l10n = AppLocalizations.of(context);
      final result = await channel.invokeMethod<String>('scan', {
        'title': l10n.s_qr_scan,
        'cancel': l10n.s_cancel,
        'image': l10n.s_read_from_file,
        'instructions': l10n.l_point_camera_scan,
        'permission': l10n.p_need_camera_permission,
        'settings': l10n.s_open_settings,
        'notFound': l10n.l_qr_not_found,
      });
      if (result == null) throw CancellationException();
      return result;
    });
  }
}
