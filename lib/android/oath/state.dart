import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../app/logging.dart';
import '../../app/models.dart';
import '../../app/state.dart';
import '../../app/views/user_interaction.dart';
import '../../cancellation_exception.dart';
import '../../core/models.dart';
import '../../oath/models.dart';
import '../../oath/state.dart';

final _log = Logger('android.oath.state');

const _methods = MethodChannel('android.oath.methods');

final androidOathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, AsyncValue<OathState>, DevicePath>(
        (ref, devicePath) => _AndroidOathStateNotifier());

class _AndroidOathStateNotifier extends OathStateNotifier {
  final _events = const EventChannel('android.oath.sessionState');
  late StreamSubscription _sub;
  _AndroidOathStateNotifier() : super() {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      if (mounted) {
        if (json == null) {
          state = const AsyncValue.loading();
        } else {
          final oathState = OathState.fromJson(json);
          state = AsyncValue.data(oathState);
        }
      }
    }, onError: (err, stackTrace) {
      state = AsyncValue.error(err, stackTrace: stackTrace);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Future<void> reset() async {
    try {
      await _methods.invokeMethod('reset');
    } catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<Pair<bool, bool>> unlock(String password,
      {bool remember = false}) async {
    try {
      final unlockResponse = jsonDecode(await _methods.invokeMethod(
          'unlock', {'password': password, 'remember': remember}));
      _log.debug('applet unlocked');

      final unlocked = unlockResponse['unlocked'] == true;
      final remembered = unlockResponse['remembered'] == true;

      return Pair(unlocked, remembered);
    } on PlatformException catch (e) {
      _log.debug('Calling unlock failed with exception: $e');
      return Pair(false, false);
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

final androidCredentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, devicePath) {
    var notifier = _AndroidCredentialListNotifier(
      ref.watch(withContextProvider),
      ref.watch(currentDeviceProvider)?.transport == Transport.usb,
    );
    return notifier;
  },
);

class _AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final _events = const EventChannel('android.oath.credentials');
  final WithContext _withContext;
  final bool _isUsbAttached;
  late StreamSubscription _sub;

  _AndroidCredentialListNotifier(this._withContext, this._isUsbAttached)
      : super() {
    _sub = _events.receiveBroadcastStream().listen((event) {
      final json = jsonDecode(event);
      state = json != null
          ? List.unmodifiable(
              (json as List).map((e) => OathPair.fromJson(e)).toList())
          : null;
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
    if (_isUsbAttached) {
      void triggerTouchPrompt() async {
        controller = await _withContext(
          (context) async => promptUserInteraction(
            context,
            icon: const Icon(Icons.touch_app),
            title: 'Touch Required',
            description: 'Touch the button on your YubiKey now.',
          ),
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
      if (CancellationException.isCancellation(pe)) {
        throw CancellationException();
      }
      rethrow;
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
      if (CancellationException.isCancellation(pe)) {
        throw CancellationException();
      }
      _log.error('Failed to add account.', pe);
      rethrow;
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
      if (CancellationException.isCancellation(pe)) {
        throw CancellationException();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    try {
      await _methods
          .invokeMethod('deleteAccount', {'credentialId': credential.id});
    } on PlatformException catch (e) {
      _log.debug('Received exception: $e');
      if (CancellationException.isCancellation(e)) {
        throw CancellationException();
      }
      rethrow;
    }
  }
}
