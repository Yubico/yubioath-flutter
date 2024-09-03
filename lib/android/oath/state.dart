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
import 'package:logging/logging.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../core/models.dart';
import '../../exception/apdu_exception.dart';
import '../../exception/cancellation_exception.dart';
import '../../exception/no_data_exception.dart';
import '../../exception/platform_exception_decoder.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';
import '../android_alert_dialog.dart';

final _log = Logger('android.oath.state');

const _methods = MethodChannel('android.oath.methods');

final androidOathStateProvider = AsyncNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState, DevicePath>(
        _AndroidOathStateNotifier.new);

class _AndroidOathStateNotifier extends OathStateNotifier {
  final _events = const EventChannel('android.oath.sessionState');
  late StreamSubscription _sub;

  @override
  FutureOr<OathState> build(DevicePath arg) {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (json == null) {
        state = AsyncValue.error(const NoDataException(), StackTrace.current);
      } else if (json == 'loading') {
        state = const AsyncValue.loading();
      } else {
        final oathState = OathState.fromJson(json);
        state = AsyncValue.data(oathState);
      }
    }, onError: (err, stackTrace) {
      state = AsyncValue.error(err, stackTrace);
    });

    ref.onDispose(_sub.cancel);

    return Completer<OathState>().future;
  }

  @override
  Future<void> reset() async {
    try {
      // await ref
      //     .read(androidAppContextHandler)
      //     .switchAppContext(Application.accounts);
      await _methods.invokeMethod('reset');
    } catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<(bool, bool)> unlock(String password, {bool remember = false}) async {
    try {
      final unlockResponse = jsonDecode(await _methods.invokeMethod(
          'unlock', {'password': password, 'remember': remember}));
      _log.debug('applet unlocked');

      final unlocked = unlockResponse['unlocked'] == true;
      final remembered = unlockResponse['remembered'] == true;

      return (unlocked, remembered);
    } on PlatformException catch (pe) {
      final decoded = pe.decode();
      if (decoded is CancellationException) {
        _log.debug('Unlock OATH cancelled');
        throw decoded;
      }
      _log.debug('Calling unlock failed with exception: $pe');
      return (false, false);
    }
  }

  @override
  Future<bool> setPassword(String? current, String password) async {
    try {
      await _methods.invokeMethod(
          'setPassword', {'current': current, 'password': password});
      return true;
    } on PlatformException catch (e) {
      _log.debug('Calling set password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<bool> unsetPassword(String current) async {
    try {
      await _methods.invokeMethod('unsetPassword', {'current': current});
      return true;
    } on PlatformException catch (e) {
      _log.debug('Calling unset password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await _methods.invokeMethod('forgetPassword');
    } on PlatformException catch (e) {
      _log.debug('Calling forgetPassword failed with exception: $e');
    }
  }
}

Exception handlePlatformException(PlatformException platformException, ref) {
  final decoded = platformException.decode();
  final l10n = ref.read(l10nProvider);
  switch (decoded) {
    case ApduException apduException:
      if (apduException.sw == 0x6985) {
        showAlertDialog(ref, l10n.l_account_add_failure_title,
            l10n.p_account_add_failure_6985);
        return CancellationException();
      }
      if (apduException.sw == 0x6982) {
        showAlertDialog(ref, l10n.l_account_add_failure_title,
            l10n.p_account_add_failure_6982);
        return CancellationException();
      }
    case PlatformException pe:
      if (pe.code == 'JobCancellationException') {
        showAlertDialog(ref, l10n.l_account_add_failure_title,
            l10n.p_account_add_failure_application_not_available);
        return CancellationException();
      } else if (pe.code == 'IllegalArgumentException') {
        showAlertDialog(ref, l10n.l_account_add_failure_title,
            l10n.p_account_add_failure_exists);
        return CancellationException();
      }
  }
  return decoded;
}

final addCredentialToAnyProvider =
    Provider((ref) => (Uri credentialUri, {bool requireTouch = false}) async {
          try {
            String resultString = await _methods.invokeMethod(
                'addAccountToAny', {
              'uri': credentialUri.toString(),
              'requireTouch': requireTouch
            });

            var result = jsonDecode(resultString);
            return OathCredential.fromJson(result['credential']);
          } on PlatformException catch (pe) {
            throw handlePlatformException(pe, ref);
          }
        });

final addCredentialsToAnyProvider = Provider(
    (ref) => (List<String> credentialUris, List<bool> touchRequired) async {
          try {
            _log.debug(
                'Calling android with ${credentialUris.length} credentials to be added');

            String resultString = await _methods.invokeMethod(
              'addAccountsToAny',
              {
                'uris': credentialUris,
                'requireTouch': touchRequired,
              },
            );

            _log.debug('Call result: $resultString');
            var result = jsonDecode(resultString);
            return result['succeeded'] == credentialUris.length;
          } on PlatformException catch (pe) {
            var decodedException = pe.decode();
            if (decodedException is CancellationException) {
              _log.debug('User cancelled adding multiple accounts');
            } else {
              _log.error('Failed to add multiple accounts.', pe);
            }

            throw decodedException;
          }
        });

final androidCredentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, devicePath) {
    var notifier =
        _AndroidCredentialListNotifier(ref.watch(withContextProvider), ref);
    return notifier;
  },
);

class _AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final _events = const EventChannel('android.oath.credentials');
  final WithContext _withContext;
  final Ref _ref;
  late StreamSubscription _sub;

  _AndroidCredentialListNotifier(this._withContext, this._ref) : super() {
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
    _sub.cancel();
    super.dispose();
  }

  @override
  Future<OathCode> calculate(OathCredential credential) async {
    // Prompt for touch if needed
    UserInteractionController? controller;
    Timer? touchTimer;
    if (_ref.read(currentDeviceProvider)?.transport == Transport.usb) {
      void triggerTouchPrompt() async {
        controller = await _withContext(
          (context) async {
            final l10n = AppLocalizations.of(context)!;
            return promptUserInteraction(
              context,
              icon: const Icon(Symbols.touch_app),
              title: l10n.s_touch_required,
              description: l10n.l_touch_button_now,
            );
          },
        );
      }

      if (credential.touchRequired) {
        triggerTouchPrompt();
      } else if (credential.oathType == OathType.hotp) {
        touchTimer =
            Timer(const Duration(milliseconds: 500), triggerTouchPrompt);
      }
    }

    try {
      final resultJson = await _methods
          .invokeMethod('calculate', {'credentialId': credential.id});
      _log.debug('Calculate', resultJson);
      return OathCode.fromJson(jsonDecode(resultJson));
    } on PlatformException catch (pe) {
      throw pe.decode();
    } finally {
      touchTimer?.cancel();
      controller?.close();
    }
  }

  @override
  Future<OathCredential> addAccount(Uri credentialUri,
      {bool requireTouch = false}) async {
    try {
      String resultString = await _methods.invokeMethod('addAccount',
          {'uri': credentialUri.toString(), 'requireTouch': requireTouch});

      var result = jsonDecode(resultString);
      return OathCredential.fromJson(result['credential']);
    } on PlatformException catch (pe) {
      throw handlePlatformException(pe, _ref);
    }
  }

  @override
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name) async {
    try {
      final response = await _methods.invokeMethod('renameAccount',
          {'credentialId': credential.id, 'name': name, 'issuer': issuer});

      _log.debug('Rename response: $response');

      var responseJson = jsonDecode(response);

      return OathCredential.fromJson(responseJson);
    } on PlatformException catch (pe) {
      _log.debug('Failed to execute renameOathCredential: ${pe.message}');
      throw pe.decode();
    }
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    try {
      await _methods
          .invokeMethod('deleteAccount', {'credentialId': credential.id});
    } on PlatformException catch (e) {
      _log.debug('Received exception: $e');
      throw e.decode();
    }
  }
}
