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
import '../../widgets/toast.dart';
import '../app_methods.dart';
import '../overlay/nfc/method_channel_notifier.dart';
import '../overlay/nfc/nfc_overlay.dart';

final _log = Logger('android.oath.state');

final androidOathStateProvider = AsyncNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState, DevicePath>(
        _AndroidOathStateNotifier.new);

class _AndroidOathStateNotifier extends OathStateNotifier {
  final _events = const EventChannel('android.oath.sessionState');
  late StreamSubscription _sub;
  late _OathMethodChannelNotifier oath =
      ref.watch(_oathMethodsProvider.notifier);

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
      await oath.invoke('reset');
    } catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<(bool, bool)> unlock(String password, {bool remember = false}) async {
    try {
      final unlockResponse = jsonDecode(await oath
          .invoke('unlock', {'password': password, 'remember': remember}));
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
      await oath
          .invoke('setPassword', {'current': current, 'password': password});
      return true;
    } on PlatformException catch (pe) {
      final decoded = pe.decode();
      if (decoded is CancellationException) {
        _log.debug('Set password cancelled');
        throw decoded;
      }
      _log.debug('Calling set password failed with exception: $pe');
      return false;
    }
  }

  @override
  Future<bool> unsetPassword(String current) async {
    try {
      await oath.invoke('unsetPassword', {'current': current});
      return true;
    } on PlatformException catch (pe) {
      final decoded = pe.decode();
      if (decoded is CancellationException) {
        _log.debug('Unset password cancelled');
        throw decoded;
      }
      _log.debug('Calling unset password failed with exception: $pe');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await oath.invoke('forgetPassword');
    } on PlatformException catch (e) {
      _log.debug('Calling forgetPassword failed with exception: $e');
    }
  }
}

Exception handlePlatformException(
    Ref ref, PlatformException platformException) {
  final decoded = platformException.decode();
  final l10n = ref.read(l10nProvider);
  final withContext = ref.read(withContextProvider);

  toast(String message, {bool popStack = false}) =>
      withContext((context) async {
        ref.read(nfcOverlay.notifier).hide();
        if (popStack) {
          Navigator.of(context).popUntil((route) {
            return route.isFirst;
          });
        }
        showToast(context, message, duration: const Duration(seconds: 4));
      });

  switch (decoded) {
    case ApduException apduException:
      if (apduException.sw == 0x6985) {
        // pop stack to show the OATH view with "Set password"
        toast(l10n.l_add_account_password_required, popStack: true);
        return CancellationException();
      }
      if (apduException.sw == 0x6982) {
        toast(l10n.l_add_account_unlock_required);
        return CancellationException();
      }
    case PlatformException pe:
      if (pe.code == 'ContextDisposedException') {
        // pop stack to show FIDO view
        toast(l10n.l_add_account_func_missing, popStack: true);
        return CancellationException();
      } else if (pe.code == 'IllegalArgumentException') {
        toast(l10n.l_add_account_already_exists);
        return CancellationException();
      }
  }
  return decoded;
}

final addCredentialToAnyProvider =
    Provider((ref) => (Uri credentialUri, {bool requireTouch = false}) async {
          final oath = ref.watch(_oathMethodsProvider.notifier);
          try {
            await preserveConnectedDeviceWhenPaused();
            var result = jsonDecode(await oath.invoke('addAccountToAny', {
              'uri': credentialUri.toString(),
              'requireTouch': requireTouch
            }));
            return OathCredential.fromJson(result['credential']);
          } on PlatformException catch (pe) {
            _log.error('Received exception: $pe');
            throw handlePlatformException(ref, pe);
          }
        });

final addCredentialsToAnyProvider = Provider(
    (ref) => (List<String> credentialUris, List<bool> touchRequired) async {
          final oath = ref.read(_oathMethodsProvider.notifier);
          try {
            await preserveConnectedDeviceWhenPaused();
            _log.debug(
                'Calling android with ${credentialUris.length} credentials to be added');
            var result = jsonDecode(await oath.invoke('addAccountsToAny',
                {'uris': credentialUris, 'requireTouch': touchRequired}));
            return result['succeeded'] == credentialUris.length;
          } on PlatformException catch (pe) {
            _log.error('Received exception: $pe');
            throw handlePlatformException(ref, pe);
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
  late _OathMethodChannelNotifier oath =
      _ref.read(_oathMethodsProvider.notifier);

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
      final resultJson =
          await oath.invoke('calculate', {'credentialId': credential.id});
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
      String resultString = await oath.invoke('addAccount',
          {'uri': credentialUri.toString(), 'requireTouch': requireTouch});
      var result = jsonDecode(resultString);
      return OathCredential.fromJson(result['credential']);
    } on PlatformException catch (pe) {
      throw handlePlatformException(_ref, pe);
    }
  }

  @override
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name) async {
    try {
      final response = await oath.invoke('renameAccount',
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
      await oath.invoke('deleteAccount', {'credentialId': credential.id});
    } on PlatformException catch (e) {
      var decoded = e.decode();
      if (decoded is CancellationException) {
        _log.debug('Account delete was cancelled.');
      } else {
        _log.debug('Received exception: $e');
      }

      throw decoded;
    }
  }
}

final _oathMethodsProvider = NotifierProvider<_OathMethodChannelNotifier, void>(
    () => _OathMethodChannelNotifier());

class _OathMethodChannelNotifier extends MethodChannelNotifier {
  _OathMethodChannelNotifier()
      : super(const MethodChannel('android.oath.methods'));
}
