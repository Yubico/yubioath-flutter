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
    return await (ref.read(credentialListProvider(devicePath).notifier))
        .calculate(credential, headless: true);
  } on CancellationException catch (_) {
    return null;
  }
}

String _getIcon() {
  if (Platform.isMacOS) {
    return 'resources/icons/systray-template.png';
  }
  return 'resources/icons/com.yubico.yubioath-32x32.png';
}

class _Systray {
  final Ref _ref;
  String? _clipboardBinary;
  TrayIcon? _trayIcon;
  Image? _icon;
  Menu? _menu;
  final List<MenuItem> _credentialItems = [];
  MenuItem? _emptyItem;
  MenuItem? _toggleItem;
  MenuItem? _quitItem;
  bool _menuIsVisible = false;
  int _menuRevision = 0;
  bool _disposed = false;
  AppLocalizations _l10n;
  DevicePath _devicePath = DevicePath([]);
  List<OathCredential> _credentials = [];
  bool _isHidden = false;

  _Systray(this._ref) : _l10n = _ref.read(l10nProvider) {
    _init();
  }

  Future<void> _init() async {
    unawaited(_initClipboardBinary());
    final trayIcon = TrayIcon.create();
    if (trayIcon == null) {
      throw StateError('Unable to create system tray icon');
    }
    _trayIcon = trayIcon;
    final icon = ImageAsset.fromAsset(_getIcon());
    if (icon == null) {
      trayIcon.dispose();
      _trayIcon = null;
      throw StateError('Unable to load system tray icon');
    }
    _icon = icon;
    final owner = WeakReference(this);
    trayIcon
      ..isIconTemplate = Platform.isMacOS
      ..icon = icon
      ..setTooltip(_l10n.app_name)
      ..setContextMenuTrigger(
        Platform.isLinux ? ContextMenuTrigger.clicked : ContextMenuTrigger.none,
      )
      ..addListener((event) => owner.target?._onTrayIconEvent(event))
      ..setVisible(true);
    await _updateContextMenu();
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
    _disposed = true;
    _trayIcon?.setContextMenu(null);
    _menu?.dispose();
    for (final item in _credentialItems) {
      item.dispose();
    }
    _emptyItem?.dispose();
    _toggleItem?.dispose();
    _quitItem?.dispose();
    _trayIcon?.dispose();
    _trayIcon = null;
    _icon?.dispose();
  }

  void _updateLocale(AppLocalizations l10n) {
    _l10n = l10n;
    _trayIcon?.setTooltip(l10n.app_name);
    unawaited(_updateContextMenu());
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

  void _onTrayIconEvent(TrayIconEvent event) {
    if (_disposed) return;
    switch (event) {
      case TrayIconClickedEvent() when Platform.isMacOS:
      case TrayIconRightClickedEvent():
        unawaited(_openContextMenu());
      case TrayIconDoubleClickedEvent() when Platform.isWindows:
        if (_isHidden) {
          _ref.read(desktopWindowStateProvider.notifier).setWindowHidden(false);
        } else {
          unawaited(windowManager.focus());
        }
      default:
        break;
    }
  }

  Future<void> _openContextMenu() async {
    await _updateContextMenu();
    if (!_disposed) _trayIcon?.openContextMenu();
  }

  Future<void> _updateContextMenu() async {
    final revision = ++_menuRevision;
    final isVisible = await windowManager.isVisible();
    if (_disposed || revision != _menuRevision) return;

    final owner = WeakReference(this);
    MenuItem createItem(String label, {void Function(_Systray)? onClick}) {
      final item = MenuItem.createWithLabelAndType(label, MenuItemType.normal);
      if (item == null) throw StateError('Unable to create system tray item');
      if (onClick != null) {
        item.addListener((event) {
          final systray = owner.target;
          if (event is MenuItemClickedEvent &&
              systray != null &&
              !systray._disposed) {
            onClick(systray);
          }
        });
      }
      return item;
    }

    final menu = _menu ?? Menu.create();
    if (menu == null) throw StateError('Unable to create system tray menu');
    if (_menu == null) {
      _toggleItem = createItem(
        _l10n.s_show_window,
        onClick: (systray) => systray._ref
            .read(desktopWindowStateProvider.notifier)
            .setWindowHidden(systray._menuIsVisible),
      );
      _quitItem = createItem(
        _l10n.s_quit,
        onClick: (_) => windowManager.close(),
      );
      menu
        ..addSeparator()
        ..addItem(_toggleItem)
        ..addSeparator()
        ..addItem(_quitItem);
      _trayIcon!.setContextMenu(menu);
      _menu = menu;
    }

    if (_credentials.isEmpty && _emptyItem == null) {
      _emptyItem = createItem(_l10n.s_no_pinned_accounts)..isEnabled = false;
      menu.insertItem(0, _emptyItem);
    } else if (_credentials.isNotEmpty && _emptyItem != null) {
      menu.removeItem(_emptyItem);
      _emptyItem!.dispose();
      _emptyItem = null;
    }
    _emptyItem?.label = _l10n.s_no_pinned_accounts;

    while (_credentialItems.length > _credentials.length) {
      final item = _credentialItems.removeLast();
      menu.removeItem(item);
      item.dispose();
    }
    while (_credentialItems.length < _credentials.length) {
      final index = _credentialItems.length;
      final item = createItem(
        getTextName(_credentials[index]),
        onClick: (systray) {
          final credential = systray._credentials[index];
          unawaited(systray._copyCode(credential, getTextName(credential)));
        },
      );
      _credentialItems.add(item);
      menu.insertItem(index, item);
    }
    for (var index = 0; index < _credentialItems.length; index++) {
      _credentialItems[index].label = getTextName(_credentials[index]);
    }
    _menuIsVisible = isVisible;
    _toggleItem!.label = isVisible ? _l10n.s_hide_window : _l10n.s_show_window;
    _quitItem!.label = _l10n.s_quit;
    if (Platform.isLinux) _trayIcon!.setContextMenu(menu);
  }

  Future<void> _copyCode(OathCredential credential, String label) async {
    final code = await _calculateCode(_devicePath, credential, _ref);
    if (code == null) return;
    if (_clipboardBinary != null) {
      _log.debug('Using custom binary to copy to clipboard: $_clipboardBinary');
      final process = await Process.start(_clipboardBinary!, []);
      process.stdin.writeln(code.value);
      await process.stdin.close();
    } else {
      await _ref.read(clipboardProvider).setText(code.value, isSensitive: true);
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
}
