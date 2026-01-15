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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:logging/logging.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../app/logging.dart';
import '../app/models.dart';
import '../app/state.dart';
import '../exception/cancellation_exception.dart';
import '../generated/l10n/app_localizations.dart';
import '../oath/models.dart';
import '../oath/state.dart';
import '../oath/views/utils.dart';
import 'state.dart';

final _log = Logger('systray');

final _favoriteAccounts =
    Provider.autoDispose<(DevicePath?, List<OathCredential>)>((ref) {
      final deviceData = ref.watch(currentDeviceDataProvider).value;
      if (deviceData != null) {
        final credentials = ref.watch(
          credentialListProvider(deviceData.node.path),
        );
        final favorites = ref.watch(favoritesProvider);
        final listed =
            credentials
                ?.map((e) => e.credential)
                .where((c) => favorites.contains(c.id))
                .toList() ??
            [];
        return (deviceData.node.path, listed);
      }
      return (null, []);
    });

final systrayProvider = Provider.autoDispose((ref) {
  final systray = _Systray(ref);

  // Keep track of which accounts to show
  ref.listen(_favoriteAccounts, (_, next) {
    systray._updateCredentials(next.$1, next.$2);
  }, fireImmediately: true);

  // Keep track of the shown/hidden state of the app
  ref.listen(windowStateProvider.select((value) => value.hidden), (_, hidden) {
    systray._setHidden(hidden);
  }, fireImmediately: true);

  // Keep track of the locale of the app
  ref.listen(l10nProvider, (_, l10n) {
    systray._updateLocale(l10n);
  });

  ref.onDispose(systray.dispose);

  return systray;
});

Future<OathCode?> _calculateCode(
  DevicePath devicePath,
  OathCredential credential,
  Ref ref,
) async {
  try {
    return await (ref.read(
      credentialListProvider(devicePath).notifier,
    )).calculate(credential, headless: true);
  } on CancellationException catch (_) {
    return null;
  }
}

String _getIcon() {
  if (Platform.isMacOS) {
    return 'resources/icons/systray-template.png';
  }
  if (Platform.isWindows) {
    return 'resources/icons/com.yubico.yubioath.ico';
  }

  // if running in a sandbox, pass the icon name since the path is not visible
  // in the host system (see https://github.com/leanflutter/tray_manager/pull/43)
  return _runningInSandbox()
      ? 'com.yubico.yubioath'
      : 'resources/icons/com.yubico.yubioath-32x32.png';
}

// copy from tray_manager package
// tray_manager-0.5.0/lib/src/helpers/sandbox.dart
bool _runningInSandbox() {
  // Check if running in a Flatpak or Snap sandbox
  return Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment.containsKey('SNAP');
}

class _Systray extends TrayListener {
  final Ref _ref;
  String? _clipboardBinary;
  int _lastClick = 0;
  AppLocalizations _l10n;
  DevicePath _devicePath = DevicePath([]);
  List<OathCredential> _credentials = [];
  bool _isHidden = false;

  _Systray(this._ref) : _l10n = _ref.read(l10nProvider) {
    _init();
  }

  Future<void> _init() async {
    unawaited(_initClipboardBinary());
    await trayManager.setIcon(_getIcon(), isTemplate: true);
    await _updateContextMenu();

    // Doesn't seem to work on Linux
    trayManager.addListener(this);
  }

  Future<void> _initClipboardBinary() async {
    final clipboardPath = Platform.environment['_YA_TRAY_CLIPBOARD'];
    if (clipboardPath != null && Platform.isLinux) {
      final file = File(clipboardPath);
      if (!(await file.exists())) {
        _log.warning(
          'Not using custom binary for clipboard: $clipboardPath. File not found.',
        );
        return;
      }
      final resolved = await file.resolveSymbolicLinks();
      final result = await Process.run(
        'ls',
        ['-nd', '--', resolved],
        environment: {'LC_ALL': 'C'},
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        //Eg. "-rwxr-xr-x 1 0 0 52384 Oct  7  2019 /usr/bin/wl-copy"
        final isFile = output[0] == '-';
        final noWorldWrite = output[8] == '-';
        final parts = output.split(RegExp(r'\s+'));
        final rootOwner = parts[2] == '0';
        final rootGroup = parts[3] == '0';
        //Ensure file, owned by root:root, not world writable
        if (isFile && noWorldWrite && rootOwner && rootGroup) {
          _clipboardBinary = resolved;
        } else {
          _log.warning('Not using custom binary for clipboard: $clipboardPath');
          _log.debug('Refusing to use custom clipboard binary: $output');
        }
      }
    }
  }

  void dispose() {
    trayManager.removeListener(this);
    trayManager.destroy();
  }

  void _updateLocale(AppLocalizations l10n) async {
    _l10n = l10n;
    if (!Platform.isLinux) {
      await trayManager.setToolTip(l10n.app_name);
    }
    await _updateContextMenu();
  }

  void _updateCredentials(
    DevicePath? devicePath,
    List<OathCredential> credentials,
  ) {
    if (!listEquals(_credentials, credentials)) {
      _devicePath = devicePath ?? _devicePath;
      _credentials = credentials;
      _updateContextMenu();
    }
  }

  Future<void> _setHidden(bool hidden) async {
    _isHidden = hidden;
    await _updateContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    if (Platform.isMacOS) {
      await _updateContextMenu();
      await trayManager.popUpContextMenu();
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastClick < 500) {
        _lastClick = 0;
        if (_isHidden) {
          _ref.read(desktopWindowStateProvider.notifier).setWindowHidden(false);
        } else {
          await windowManager.focus();
        }
      } else {
        _lastClick = now;
      }
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await _updateContextMenu();
    await trayManager.popUpContextMenu();
  }

  Future<void> _updateContextMenu() async {
    final isVisible = await windowManager.isVisible();
    await trayManager.setContextMenu(
      Menu(
        items: [
          ..._credentials.map((e) {
            final label = getTextName(e);
            return MenuItem(
              label: label,
              onClick: (_) async {
                final code = await _calculateCode(_devicePath, e, _ref);
                if (code != null) {
                  if (_clipboardBinary != null) {
                    // Copy to clipboard via another executable, which can be needed for Wayland
                    _log.debug(
                      'Using custom binary to copy to clipboard: $_clipboardBinary',
                    );
                    final process = await Process.start(_clipboardBinary!, []);
                    process.stdin.writeln(code.value);
                    await process.stdin.close();
                  } else {
                    await _ref
                        .read(clipboardProvider)
                        .setText(code.value, isSensitive: true);
                  }
                  final notification = LocalNotification(
                    title: _l10n.s_code_copied,
                    body: _l10n.p_target_copied_clipboard(label),
                    silent: true,
                  );
                  await notification.show();
                  await Future.delayed(const Duration(seconds: 4));
                  await notification.close();
                }
              },
            );
          }),
          if (_credentials.isEmpty)
            MenuItem(label: _l10n.s_no_pinned_accounts, disabled: true),
          MenuItem.separator(),
          MenuItem(
            label: !isVisible ? _l10n.s_show_window : _l10n.s_hide_window,
            onClick: (_) {
              _ref
                  .read(desktopWindowStateProvider.notifier)
                  .setWindowHidden(isVisible);
            },
          ),
          MenuItem.separator(),
          MenuItem(
            label: _l10n.s_quit,
            onClick: (_) {
              // We don't use CloseIntent as it requires a Context, which we will not have if the window hasn't been shown yet.
              windowManager.close();
            },
          ),
        ],
      ),
    );
  }
}
