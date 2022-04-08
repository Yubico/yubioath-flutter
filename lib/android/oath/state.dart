import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/api/impl.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/oath/state.dart';

import '../../oath/models.dart';
import 'command_providers.dart';

final _log = Logger('android.oath.state');

class CancelException implements Exception {}

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
      _ref.read(androidCredentialsProvider.notifier).reset();
    } catch (e) {
      _log.config('Calling reset failed with exception: $e');
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
        _log.config('applet unlocked');
        setData(state.value!.copyWith(
          locked: false,
          remembered: remembered,
        ));
      }
      return Pair(unlocked, remembered);
    } on PlatformException catch (e) {
      _log.config('Calling unlock failed with exception: $e');
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
      _log.config('Calling set password failed with exception: $e');
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
      _log.config('Calling unset password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await _api.forgetPassword();
      setData(state.value!.copyWith(remembered: false));
    } on PlatformException catch (e) {
      _log.config('Calling forgetPassword failed with exception: $e');
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
    final OathCode code;
    var resultJson = await _api.calculate(credential.id);
    var result = jsonDecode(resultJson);
    code = OathCode.fromJson(result);
    _log.config('Calculate', jsonEncode(code));
    if (update && mounted) {
      final creds = state!.toList();
      final i = creds.indexWhere((e) => e.credential.id == credential.id);
      state = creds..[i] = creds[i].copyWith(code: code);
    }
    return code;
  }

  @override
  Future<OathCredential> addAccount(Uri credentialUri,
      {bool requireTouch = false}) async {
    String resultString =
        await _api.addAccount(credentialUri.toString(), requireTouch);

    var result = jsonDecode(resultString);
    final newCredential = OathCredential.fromJson(result['credential']);
    final newCode =
        result['code'] != null ? OathCode.fromJson(result['code']) : null;
    final pair = OathPair(newCredential, newCode);

    if (mounted) {
      final newState = state!.toList();

      /// remove any duplicates to our new credential
      newState.removeWhere((e) => e.credential == newCredential);
      newState.add(pair);
      state = newState;
    }

    return pair.credential;
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
    } on PlatformException catch (e) {
      _log.config('Failed to execute renameOathCredential: ${e.message}');
    }

    return credential;
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    try {
      await _api.deleteAccount(credential.id);

      if (mounted) {
        state = state!.toList()..removeWhere((e) => e.credential == credential);
      }
    } catch (e) {
      _log.config('Call to delete credential failed: $e');
    }
  }

  refresh() async {
    if (_currentDevice == null) return;
    _log.config('refreshing credentials...');

    final pairs = [];

    try {
      var resultString = await _api.refreshCodes();
      var result = jsonDecode(resultString);

      for (var e in result['entries']) {
        final credential = OathCredential.fromJson(e['credential']);
        final code = e['code'] == null ? null : OathCode.fromJson(e['code']);
        pairs.add(OathPair(credential, code));
      }

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
      _log.config('Failure refreshing codes: $e');
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    if (_currentDevice == null) return;
    if (state == null) {
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
        _timer = null;
      } else {
        final earliest = expirations.reduce(min) * 1000;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (earliest < now) {
          refresh();
        } else {
          _timer = Timer(Duration(milliseconds: earliest - now), refresh);
        }
      }
    }
  }
}
