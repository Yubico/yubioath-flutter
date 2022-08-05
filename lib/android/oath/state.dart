import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/api/impl.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/oath/state.dart';

import '../../cancellation_exception.dart';
import '../../oath/models.dart';
import 'command_providers.dart';

final _log = Logger('android.oath.state');

final oathApiProvider = StateProvider((_) => OathApi());

final androidOathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, AsyncValue<OathState>, DevicePath>(
        (ref, devicePath) => _AndroidOathStateNotifier(
            ref.watch(androidStateProvider), ref.watch(oathApiProvider), ref));

class _AndroidOathStateNotifier extends OathStateNotifier {
  final OathApi _api;
  final Ref _ref;

  _AndroidOathStateNotifier(OathState? newState, this._api, this._ref)
      : super() {
    if (newState != null) {
      setData(newState);
    }
  }

  @override
  Future<void> reset() async {
    try {
      await _api.reset();
      setData(state.value!
          .copyWith(locked: false, remembered: false, hasKey: false));
      _ref.refresh(androidStateProvider);
    } catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<Pair<bool, bool>> unlock(String password,
      {bool remember = false}) async {
    try {
      final unlockResponse = await _api.unlock(password, remember);

      final unlocked = unlockResponse.isUnlocked == true;
      final remembered = unlockResponse.isRemembered == true;

      if (unlocked) {
        _log.debug('applet unlocked');
        setData(state.value!.copyWith(
          locked: false,
          remembered: remembered,
        ));
      }
      return Pair(unlocked, remembered);
    } on PlatformException catch (e) {
      _log.debug('Calling unlock failed with exception: $e');
      return Pair(false, false);
    }
  }

  @override
  Future<bool> setPassword(String? current, String password) async {
    try {
      await _api.setPassword(current, password);
      setData(state.value!.copyWith(hasKey: true));
      return true;
    } on PlatformException catch (e) {
      _log.debug('Calling set password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<bool> unsetPassword(String current) async {
    try {
      await _api.unsetPassword(current);
      setData(state.value!.copyWith(hasKey: false, locked: false));
      return true;
    } on PlatformException catch (e) {
      _log.debug('Calling unset password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await _api.forgetPassword();
      setData(state.value!.copyWith(remembered: false));
    } on PlatformException catch (e) {
      _log.debug('Calling forgetPassword failed with exception: $e');
    }
  }
}

final androidCredentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, devicePath) {
    var notifier = _AndroidCredentialListNotifier(
      ref.watch(currentDeviceProvider),
      ref.watch(oathApiProvider),
      ref.watch(androidCredentialsProvider),
    );
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._notifyWindowState(windowState);
    }, fireImmediately: true);
    return notifier;
  },
);

class _AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final DeviceNode? _currentDevice;
  final OathApi _api;
  Timer? _timer;

  _AndroidCredentialListNotifier(
      this._currentDevice, this._api, List<OathPair>? pairs)
      : super() {
    state = pairs;
    _scheduleRefresh();
  }

  void _notifyWindowState(WindowState windowState) {
    if (_currentDevice == null) return;
    if (windowState.active) {
      _scheduleRefresh();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  @protected
  set state(List<OathPair>? value) {
    super.state = value != null ? List.unmodifiable(value) : null;
  }

  @override
  Future<OathCode> calculate(OathCredential credential,
      {bool update = true}) async {
    try {
      var resultJson = await _api.calculate(credential.id);
      var result = jsonDecode(resultJson);
      final OathCode code = OathCode.fromJson(result);
      _log.debug('Calculate', jsonEncode(code));
      if (update && mounted) {
        final creds = state!.toList();
        final i = creds.indexWhere((e) => e.credential.id == credential.id);
        state = creds..[i] = creds[i].copyWith(code: code);
      }
      return code;
    } on PlatformException catch (pe) {
      if (CancellationException.isCancellation(pe)) {
        throw CancellationException();
      }
      rethrow;
    }
  }

  @override
  Future<OathCredential> addAccount(Uri credentialUri,
      {bool requireTouch = false}) async {
    try {
      String resultString =
          await _api.addAccount(credentialUri.toString(), requireTouch);

      var result = jsonDecode(resultString);
      var addedCredential = OathCredential.fromJson(result['credential']);

      var addedCredCode =
          result['code'] != null ? OathCode.fromJson(result['code']) : null;

      if (mounted) {
        final newState = state!.toList();
        final index =
            newState.indexWhere((e) => e.credential == addedCredential);
        if (index > -1) {
          newState.removeAt(index);
        }
        newState.add(OathPair(
          addedCredential,
          addedCredCode,
        ));
        state = newState;
      }

      refresh();
      return addedCredential;
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
      String response;
      response = await _api.renameAccount(credential.id, name, issuer);

      var responseJson = jsonDecode(response);

      var renamedCredential = OathCredential.fromJson(responseJson);

      if (mounted) {
        final newState = state!.toList();
        final index = newState.indexWhere((e) => e.credential == credential);
        final oldPair = newState.removeAt(index);
        newState.add(OathPair(
          renamedCredential,
          oldPair.code,
        ));
        state = newState;
      }

      return renamedCredential;
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
      await _api.deleteAccount(credential.id);

      if (mounted) {
        state = state!.toList()..removeWhere((e) => e.credential == credential);
      }
    } on PlatformException catch (e) {
      _log.debug('Received exception: $e');
      if (CancellationException.isCancellation(e)) {
        throw CancellationException();
      }
      rethrow;
    }
  }

  refresh() async {
    if (_currentDevice == null) return;
    _log.debug('refreshing credentials...');

    try {
      var resultString = await _api.refreshCodes();
      var result = jsonDecode(resultString);

      final pairs = result.map((e) => OathPair.fromJson(e)).toList();

      if (mounted) {
        final current = state?.toList() ?? [];
        for (var pair in pairs) {
          final i =
              current.indexWhere((e) => e.credential.id == pair.credential.id);
          if (i < 0) {
            current.add(pair);
          } else if (pair.code != null) {
            current[i] = current[i].copyWith(code: pair.code);
          }
        }
        state = current;
        _scheduleRefresh();
      }
    } catch (e) {
      _log.debug('Failure refreshing codes: $e');
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    if (_currentDevice == null) return;
    if (state == null) {
      _log.debug('No OATH state, refresh immediately');
      refresh();
    } else if (mounted) {
      final expirations = (state ?? [])
          .where((pair) =>
              pair.credential.oathType == OathType.totp &&
              !pair.credential.touchRequired)
          .map((e) => e.code)
          .whereType<OathCode>()
          .map((e) => e.validTo);
      if (expirations.isEmpty) {
        _log.debug('No expirations, no refresh');
        _timer = null;
      } else {
        final earliest = expirations.reduce(min) * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (earliest < now) {
          _log.debug('Already expired, refresh immediately');
          refresh();
        } else {
          _log.debug('Schedule refresh in ${earliest - now}ms');
          _timer = Timer(Duration(milliseconds: earliest - now), refresh);
        }
      }
    }
  }
}
