/*
 * Copyright (C) 2023 Yubico.
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

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../app/models.dart';
import '../app/state.dart';
import '../exception/cancellation_exception.dart';
import '../oath/models.dart';
import '../oath/state.dart';

final systrayProvider = Provider((ref) {
  return Systray(ref);
});

Future<OathCode?> _calculateCode(
    DevicePath devicePath, OathCredential credential, Ref ref) async {
  try {
    return await ref
        .read(credentialListProvider(devicePath).notifier)
        .calculate(credential);
  } on CancellationException catch (_) {
    return null;
  }
}

class Systray extends TrayListener {
  final Ref _ref;
  int _lastClick = 0;
  Systray(this._ref) {
    _init();
  }

  void _init() async {
    await trayManager.setIcon(Platform.isWindows
        ? 'assets/graphics/systray.ico'
        : 'assets/graphics/app-icon.png');
    await trayManager.setToolTip('Yubico Authenticator');

    trayManager.addListener(this);
  }

  @override
  void onTrayIconMouseDown() async {
    if (!await windowManager.isVisible()) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastClick < 500) {
        _lastClick = 0;
        await windowManager.show();
      } else {
        _lastClick = now;
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    final devicePath = _ref.read(currentDeviceProvider)?.path;
    Iterable<OathCredential> credentials = [];
    if (devicePath != null) {
      final favorites = _ref.read(favoritesProvider);
      credentials = _ref
              .read(credentialsProvider)
              ?.where((element) => favorites.contains(element.id)) ??
          [];
    }
    await trayManager.setContextMenu(
      Menu(
        items: [
          ...credentials.map(
            (e) => MenuItem(
              label: '${e.issuer} (${e.name})',
              onClick: (_) async {
                final code = await _calculateCode(devicePath!, e, _ref);
                if (code != null) {
                  final clipboard = _ref.read(clipboardProvider);
                  await clipboard.setText(code.value, isSensitive: true);

                  final notification = LocalNotification(
                    title: 'Code copied',
                    body: '${e.issuer} (${e.name}) copied to clipboard.',
                    silent: true,
                  );
                  await notification.show();
                  await Future.delayed(const Duration(seconds: 4));
                  await notification.close();
                }
              },
            ),
          ),
          if (credentials.isNotEmpty) MenuItem.separator(),
          MenuItem(
            label: 'Show/Hide window',
            onClick: (_) async {
              if (await windowManager.isVisible()) {
                await windowManager.hide();
              } else {
                await windowManager.show();
              }
            },
          ),
          MenuItem.separator(),
          MenuItem(
              label: 'Quit',
              onClick: (_) async {
                await windowManager.close();
              }),
        ],
      ),
    );
    await trayManager.popUpContextMenu();
  }
}
