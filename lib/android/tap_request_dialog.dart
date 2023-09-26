/*
 * Copyright (C) 2022-2023 Yubico.
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
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/state.dart';
import '../app/views/user_interaction.dart';
import 'views/nfc/nfc_activity_widget.dart';

const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

// _DDesc contains id of title resource for the dialog
enum _DialogTitle {
  tapKey,
  operationSuccessful,
  operationFailed,
  invalid;

  static _DialogTitle fromId(int? id) =>
      const {
        0: _DialogTitle.tapKey,
        1: _DialogTitle.operationSuccessful,
        2: _DialogTitle.operationFailed
      }[id] ??
      _DialogTitle.invalid;
}

// _DDesc contains action description in the dialog
enum _DialogDescription {
  // oath descriptions
  oathResetApplet,
  oathUnlockSession,
  oathSetPassword,
  oathUnsetPassword,
  oathAddAccount,
  oathRenameAccount,
  oathDeleteAccount,
  oathCalculateCode,
  oathActionFailure,
  oathAddMultipleAccounts,
  invalid;

  static const int dialogDescriptionOathIndex = 100;

  static _DialogDescription fromId(int? id) =>
      const {
        dialogDescriptionOathIndex + 0: _DialogDescription.oathResetApplet,
        dialogDescriptionOathIndex + 1: _DialogDescription.oathUnlockSession,
        dialogDescriptionOathIndex + 2: _DialogDescription.oathSetPassword,
        dialogDescriptionOathIndex + 3: _DialogDescription.oathUnsetPassword,
        dialogDescriptionOathIndex + 4: _DialogDescription.oathAddAccount,
        dialogDescriptionOathIndex + 5: _DialogDescription.oathRenameAccount,
        dialogDescriptionOathIndex + 6: _DialogDescription.oathDeleteAccount,
        dialogDescriptionOathIndex + 7: _DialogDescription.oathCalculateCode,
        dialogDescriptionOathIndex + 8: _DialogDescription.oathActionFailure,
        dialogDescriptionOathIndex + 9:
            _DialogDescription.oathAddMultipleAccounts
      }[id] ??
      _DialogDescription.invalid;
}

final androidDialogProvider = Provider<_DialogProvider>(
  (ref) {
    return _DialogProvider(ref.watch(withContextProvider));
  },
);

class _DialogProvider {
  final WithContext _withContext;
  final Widget _icon = const NfcActivityWidget(width: 64, height: 64);
  UserInteractionController? _controller;

  _DialogProvider(this._withContext) {
    _channel.setMethodCallHandler((call) async {
      final args = jsonDecode(call.arguments);
      switch (call.method) {
        case 'close':
          _closeDialog();
          break;
        case 'show':
          await _showDialog(args['title'], args['description']);
          break;
        case 'state':
          await _updateDialogState(args['title'], args['description']);
          break;
        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
  }

  void _closeDialog() {
    _controller?.close();
    _controller = null;
  }

  String _getTitle(BuildContext context, int? titleId) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_DialogTitle.fromId(titleId)) {
      _DialogTitle.tapKey => l10n.s_nfc_dialog_tap_key,
      _DialogTitle.operationSuccessful => l10n.s_nfc_dialog_operation_success,
      _DialogTitle.operationFailed => l10n.s_nfc_dialog_operation_failed,
      _ => ''
    };
  }

  String _getDialogDescription(BuildContext context, int? descriptionId) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_DialogDescription.fromId(descriptionId)) {
      _DialogDescription.oathResetApplet => l10n.s_nfc_dialog_oath_reset,
      _DialogDescription.oathUnlockSession => l10n.s_nfc_dialog_oath_unlock,
      _DialogDescription.oathSetPassword => l10n.s_nfc_dialog_oath_set_password,
      _DialogDescription.oathUnsetPassword =>
        l10n.s_nfc_dialog_oath_unset_password,
      _DialogDescription.oathAddAccount => l10n.s_nfc_dialog_oath_add_account,
      _DialogDescription.oathRenameAccount =>
        l10n.s_nfc_dialog_oath_rename_account,
      _DialogDescription.oathDeleteAccount =>
        l10n.s_nfc_dialog_oath_delete_account,
      _DialogDescription.oathCalculateCode =>
        l10n.s_nfc_dialog_oath_calculate_code,
      _DialogDescription.oathActionFailure => l10n.s_nfc_dialog_oath_failure,
      _DialogDescription.oathAddMultipleAccounts =>
        l10n.s_nfc_dialog_oath_add_multiple_accounts,
      _ => ' '
    };
  }

  Future<void> _updateDialogState(int? title, int? description) async {
    await _withContext((context) async {
      _controller?.updateContent(
        title: _getTitle(context, title),
        description: _getDialogDescription(context, description),
        icon: (_DialogDescription.fromId(description) !=
                _DialogDescription.oathActionFailure)
            ? _icon
            : const Icon(Icons.warning_amber_rounded, size: 64),
      );
    });
  }

  Future<void> _showDialog(int title, int description) async {
    _controller = await _withContext((context) async {
      return promptUserInteraction(
        context,
        title: _getTitle(context, title),
        description: _getDialogDescription(context, description),
        icon: _icon,
        onCancel: () {
          _channel.invokeMethod('cancel');
        },
      );
    });
  }
}
