/*
 * Copyright (C) 2026 Yubico.
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AccessibilityAnnouncer {
  static const MethodChannel _windowsChannel = MethodChannel(
    'yubico_authenticator/a11y',
  );

  static Future<void> announce(BuildContext context, String message) async {
    final announceText = message.trim().isEmpty ? message : message.trim();
    if (announceText.isEmpty) {
      return;
    }

    final view = View.of(context);
    final direction = Directionality.of(context);
    final canAnnounce = MediaQuery.supportsAnnounceOf(context);

    if (Platform.isWindows) {
      try {
        await _windowsChannel.invokeMethod<void>('announce', announceText);
        return;
      } catch (_) {
        // Fall back to framework announcements below.
      }
    }

    if (!canAnnounce) {
      return;
    }

    await SemanticsService.sendAnnouncement(view, announceText, direction);
  }
}
