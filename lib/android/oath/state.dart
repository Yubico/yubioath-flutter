/*
 * Copyright (C) 2022-2026 Yubico.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../exception/app_exception.dart';
import '../../exception/no_data_exception.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';
import '../overlay/nfc/method_channel_notifier.dart';
import '../overlay/nfc/nfc_overlay.dart';

final _log = Logger('android.oath.state');

class AndroidOathStateNotifier extends OathStateNotifier {
  final _events = const EventChannel('android.oath.sessionState');
  late StreamSubscription _sub;
  late OathMethodChannelNotifier oath = ref.watch(
    _oathMethodsProvider.notifier,
  );

  AndroidOathStateNotifier(super.devicePath);

  @override
  FutureOr<OathState> build() {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final json = jsonDecode(event);
        if (json == null) {
          state = AsyncValue.error(const NoDataException(), StackTrace.current);
        } else if (json == 'loading') {
          state = const AsyncValue.loading();
        } else {
          final oathState = OathState.fromJson(json);
          state = AsyncValue.data(oathState);
        }
      },
      onError: (err, stackTrace) {
        state = AsyncValue.error(err, stackTrace);
      },
    );

    ref.onDispose(_sub.cancel);

    return Completer<OathState>().future;
  }

  @override
  Future<void> reset() async {
    try {
      await oath.invoke('reset');
    } on CancellationException {
      rethrow;
    } on AppException catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<(bool, bool)> unlock(String password, {bool remember = false}) async {
    try {
      final unlockResponse = jsonDecode(
        await oath.invoke('unlock', {
          'password': password,
          'remember': remember,
        }),
      );
      _log.debug('applet unlocked');

      final unlocked = unlockResponse['unlocked'] == true;
      final remembered = unlockResponse['remembered'] == true;

      return (unlocked, remembered);
    } on CancellationException {
      _log.debug('Unlock OATH cancelled');
      rethrow;
    } on AppException catch (e) {
      _log.debug('Calling unlock failed with exception: $e');
      return (false, false);
    }
  }

  @override
  Future<bool> setPassword(String? current, String password) async {
    try {
      await oath.invoke('setPassword', {
        'current': current,
        'password': password,
      });
      return true;
    } on CancellationException {
      _log.debug('Set password cancelled');
      rethrow;
    } on AppException catch (e) {
      _log.debug('Calling set password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<bool> unsetPassword(String current) async {
    try {
      await oath.invoke('unsetPassword', {'current': current});
      return true;
    } on CancellationException {
      _log.debug('Unset password cancelled');
      rethrow;
    } on AppException catch (e) {
      _log.debug('Calling unset password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await oath.invoke('forgetPassword');
    } on AppException catch (e) {
      _log.debug('Calling forgetPassword failed with exception: $e');
    }
  }
}

/// Hides the NFC overlay at once for the add-account errors that the view
/// explains with a message of its own.
void _hideOverlayOnAddAccountError(Ref ref, AppException e) {
  if (e is AuthRequiredException ||
      e is PasswordRequiredException ||
      e is NotSupportedException ||
      e is AlreadyExistsException) {
    ref.read(nfcOverlay.notifier).hide();
  }
}

final addCredentialToAnyProvider = Provider(
  (ref) => (Uri credentialUri, {bool requireTouch = false}) async {
    final oath = ref.watch(_oathMethodsProvider.notifier);
    try {
      var result = jsonDecode(
        await oath.invoke('addAccountToAny', {
          'uri': credentialUri.toString(),
          'requireTouch': requireTouch,
        }),
      );
      return OathCredential.fromJson(result['credential']);
    } on AppException catch (e) {
      _log.error('Received exception: $e');
      _hideOverlayOnAddAccountError(ref, e);
      rethrow;
    }
  },
);

final addCredentialsToAnyProvider = Provider(
  (ref) => (List<String> credentialUris, List<bool> touchRequired) async {
    final oath = ref.read(_oathMethodsProvider.notifier);
    try {
      _log.debug(
        'Calling android with ${credentialUris.length} credentials to be added',
      );
      var result = jsonDecode(
        await oath.invoke('addAccountsToAny', {
          'uris': credentialUris,
          'requireTouch': touchRequired,
        }),
      );
      return result['succeeded'] == credentialUris.length;
    } on AppException catch (e) {
      _log.error('Received exception: $e');
      _hideOverlayOnAddAccountError(ref, e);
      rethrow;
    }
  },
);

class AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final _events = const EventChannel('android.oath.credentials');
  final WithContext _withContext;
  final Ref _ref;
  late StreamSubscription _sub;
  late OathMethodChannelNotifier oath = _ref.read(
    _oathMethodsProvider.notifier,
  );
  Timer? _touchTimer;

  AndroidCredentialListNotifier(this._withContext, this._ref) : super() {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      List<OathPair>? newState = json != null
          ? List.from((json as List).map((e) => OathPair.fromJson(e)).toList())
          : null;
      state = newState;
    });
  }

  @override
  void dispose() {
    _touchTimer?.cancel();
    _sub.cancel();
    super.dispose();
  }

  @override
  Future<OathCode> calculate(
    OathCredential credential, {
    bool headless = true,
    bool update = true,
  }) async {
    // Prompt for touch if needed
    UserInteractionController? controller;
    if (_ref.read(currentDeviceProvider)?.transport == Transport.usb) {
      void triggerTouchPrompt() async {
        controller = await _withContext((context) async {
          final l10n = AppLocalizations.of(context);
          return promptUserInteraction(
            context,
            icon: const Icon(Symbols.touch_app),
            title: l10n.s_touch_required,
            description: l10n.l_touch_button_now,
          );
        });
      }

      // cancel any ongoing timer
      _touchTimer?.cancel();
      _touchTimer = null;

      if (credential.touchRequired) {
        triggerTouchPrompt();
      } else if (credential.oathType == OathType.hotp) {
        _touchTimer = Timer(
          const Duration(milliseconds: 500),
          triggerTouchPrompt,
        );
      }
    }

    try {
      final resultJson = await oath.invoke('calculate', {
        'credentialId': credential.id,
      });
      _log.debug('Calculate', resultJson);
      return OathCode.fromJson(jsonDecode(resultJson));
    } finally {
      _touchTimer?.cancel();
      _touchTimer = null;
      controller?.close();
    }
  }

  @override
  Future<OathCredential> addAccount(
    Uri credentialUri, {
    bool requireTouch = false,
  }) async {
    try {
      String resultString = await oath.invoke('addAccount', {
        'uri': credentialUri.toString(),
        'requireTouch': requireTouch,
      });
      var result = jsonDecode(resultString);
      return OathCredential.fromJson(result['credential']);
    } on AppException catch (e) {
      _hideOverlayOnAddAccountError(_ref, e);
      rethrow;
    }
  }

  @override
  Future<OathCredential> renameAccount(
    OathCredential credential,
    String? issuer,
    String name,
  ) async {
    try {
      final response = await oath.invoke('renameAccount', {
        'credentialId': credential.id,
        'name': name,
        'issuer': issuer,
      });
      _log.debug('Rename response: $response');

      var responseJson = jsonDecode(response);

      return OathCredential.fromJson(responseJson);
    } on AppException catch (e) {
      _log.debug('Failed to execute renameOathCredential: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    try {
      await oath.invoke('deleteAccount', {'credentialId': credential.id});
    } on CancellationException {
      _log.debug('Account delete was cancelled.');
      rethrow;
    } on AppException catch (e) {
      _log.debug('Received exception: $e');
      rethrow;
    }
  }
}

final _oathMethodsProvider = NotifierProvider<OathMethodChannelNotifier, void>(
  () => OathMethodChannelNotifier(),
);

class OathMethodChannelNotifier extends MethodChannelNotifier {
  OathMethodChannelNotifier()
    : super(
        const MethodChannel('android.oath.methods'),
        throwAppExceptions: true,
      );
}
