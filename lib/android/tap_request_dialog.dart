/*
 * Copyright (C) 2022-2024 Yubico.
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
import 'package:material_symbols_icons/symbols.dart';

import '../app/state.dart';
import '../app/views/user_interaction.dart';

const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

// _DIcon identifies the icon which should be displayed on the dialog
enum _DIcon {
  nfcIcon,
  successIcon,
  failureIcon,
  invalid;

  static _DIcon fromId(int? id) =>
      const {
        0: _DIcon.nfcIcon,
        1: _DIcon.successIcon,
        2: _DIcon.failureIcon
      }[id] ??
      _DIcon.invalid;
}

// _DDesc contains id of title resource for the dialog
enum _DTitle {
  tapKey,
  operationSuccessful,
  operationFailed,
  invalid;

  static _DTitle fromId(int? id) =>
      const {
        0: _DTitle.tapKey,
        1: _DTitle.operationSuccessful,
        2: _DTitle.operationFailed
      }[id] ??
      _DTitle.invalid;
}

// _DDesc contains action description in the dialog
enum _DDesc {
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
  // FIDO descriptions
  fidoResetApplet,
  fidoUnlockSession,
  fidoSetPin,
  fidoDeleteCredential,
  fidoDeleteFingerprint,
  fidoRenameFingerprint,
  fidoRegisterFingerprint,
  fidoEnableEnterpriseAttestation,
  fidoActionFailure,
  // Others
  invalid;

  static const int dialogDescriptionOathIndex = 100;
  static const int dialogDescriptionFidoIndex = 200;

  static _DDesc fromId(int? id) =>
      const {
        dialogDescriptionOathIndex + 0: oathResetApplet,
        dialogDescriptionOathIndex + 1: oathUnlockSession,
        dialogDescriptionOathIndex + 2: oathSetPassword,
        dialogDescriptionOathIndex + 3: oathUnsetPassword,
        dialogDescriptionOathIndex + 4: oathAddAccount,
        dialogDescriptionOathIndex + 5: oathRenameAccount,
        dialogDescriptionOathIndex + 6: oathDeleteAccount,
        dialogDescriptionOathIndex + 7: oathCalculateCode,
        dialogDescriptionOathIndex + 8: oathActionFailure,
        dialogDescriptionOathIndex + 9: oathAddMultipleAccounts,
        dialogDescriptionFidoIndex + 0: fidoResetApplet,
        dialogDescriptionFidoIndex + 1: fidoUnlockSession,
        dialogDescriptionFidoIndex + 2: fidoSetPin,
        dialogDescriptionFidoIndex + 3: fidoDeleteCredential,
        dialogDescriptionFidoIndex + 4: fidoDeleteFingerprint,
        dialogDescriptionFidoIndex + 5: fidoRenameFingerprint,
        dialogDescriptionFidoIndex + 6: fidoRegisterFingerprint,
        dialogDescriptionFidoIndex + 7: fidoEnableEnterpriseAttestation,
        dialogDescriptionFidoIndex + 8: fidoActionFailure,
      }[id] ??
      _DDesc.invalid;
}

final androidDialogProvider = Provider<_DialogProvider>(
  (ref) {
    return _DialogProvider(ref.watch(withContextProvider));
  },
);

class _DialogProvider {
  final WithContext _withContext;
  UserInteractionController? _controller;

  _DialogProvider(this._withContext) {
    _channel.setMethodCallHandler((call) async {
      final args = jsonDecode(call.arguments);
      switch (call.method) {
        case 'close':
          _closeDialog();
          break;
        case 'show':
          await _showDialog(args['title'], args['description'], args['icon']);
          break;
        case 'state':
          await _updateDialogState(
              args['title'], args['description'], args['icon']);
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

  Widget? _getIcon(int? icon) => switch (_DIcon.fromId(icon)) {
        _DIcon.nfcIcon => const Icon(Symbols.contactless),
        _DIcon.successIcon => const Icon(Symbols.check_circle),
        _DIcon.failureIcon => const Icon(Symbols.error),
        _ => null,
      };

  String _getTitle(BuildContext context, int? titleId) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_DTitle.fromId(titleId)) {
      _DTitle.tapKey => l10n.l_nfc_dialog_tap_key,
      _DTitle.operationSuccessful => l10n.s_nfc_dialog_operation_success,
      _DTitle.operationFailed => l10n.s_nfc_dialog_operation_failed,
      _ => ''
    };
  }

  String _getDialogDescription(BuildContext context, int? descriptionId) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_DDesc.fromId(descriptionId)) {
      _DDesc.oathResetApplet => l10n.s_nfc_dialog_oath_reset,
      _DDesc.oathUnlockSession => l10n.s_nfc_dialog_oath_unlock,
      _DDesc.oathSetPassword => l10n.s_nfc_dialog_oath_set_password,
      _DDesc.oathUnsetPassword => l10n.s_nfc_dialog_oath_unset_password,
      _DDesc.oathAddAccount => l10n.s_nfc_dialog_oath_add_account,
      _DDesc.oathRenameAccount => l10n.s_nfc_dialog_oath_rename_account,
      _DDesc.oathDeleteAccount => l10n.s_nfc_dialog_oath_delete_account,
      _DDesc.oathCalculateCode => l10n.s_nfc_dialog_oath_calculate_code,
      _DDesc.oathActionFailure => l10n.s_nfc_dialog_oath_failure,
      _DDesc.oathAddMultipleAccounts =>
        l10n.s_nfc_dialog_oath_add_multiple_accounts,
      _DDesc.fidoResetApplet => l10n.s_nfc_dialog_fido_reset,
      _DDesc.fidoUnlockSession => l10n.s_nfc_dialog_fido_unlock,
      _DDesc.fidoSetPin => l10n.l_nfc_dialog_fido_set_pin,
      _DDesc.fidoDeleteCredential => l10n.s_nfc_dialog_fido_delete_credential,
      _DDesc.fidoDeleteFingerprint => l10n.s_nfc_dialog_fido_delete_fingerprint,
      _DDesc.fidoRenameFingerprint => l10n.s_nfc_dialog_fido_rename_fingerprint,
      _DDesc.fidoActionFailure => l10n.s_nfc_dialog_fido_failure,
      _ => ''
    };
  }

  Future<void> _updateDialogState(
      int? title, int? description, int? dialogIcon) async {
    final icon = _getIcon(dialogIcon);
    await _withContext((context) async {
      _controller?.updateContent(
        title: _getTitle(context, title),
        description: _getDialogDescription(context, description),
        icon: icon != null
            ? IconTheme(
                data: IconTheme.of(context).copyWith(size: 64),
                child: icon,
              )
            : null,
      );
    });
  }

  Future<void> _showDialog(int title, int description, int? dialogIcon) async {
    final icon = _getIcon(dialogIcon);
    _controller = await _withContext((context) async => promptUserInteraction(
          context,
          title: _getTitle(context, title),
          description: _getDialogDescription(context, description),
          icon: icon != null
              ? IconTheme(
                  data: IconTheme.of(context).copyWith(size: 64),
                  child: icon,
                )
              : null,
          onCancel: () {
            _channel.invokeMethod('cancel');
          },
        ));
  }
}
