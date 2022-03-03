import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/api/impl.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/oath/state.dart';

import '../../app/state.dart';
import '../../oath/models.dart';
import 'command_providers.dart';

final _log = Logger('android.oath.state');

class CancelException implements Exception {}

final oathApiProvider = StateProvider((_) => OathApi());

final androidOathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, OathState?, DevicePath>((ref, devicePath) =>
        _AndroidOathStateNotifier(
            ref.watch(oathStateCommandProvider), ref.watch(oathApiProvider)));

class _AndroidOathStateNotifier extends OathStateNotifier {
  final OathApi _api;

  _AndroidOathStateNotifier(OathState? newState, this._api) : super() {
    state = newState;
  }

  @override
  Future<void> reset() async {
    try {
      await _api.reset();
    } catch (e) {
      _log.info('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<Pair<bool, bool>> unlock(String password,
      {bool remember = false}) async {
    try {
      final unlockSuccess = await _api.unlock(password, remember);

      if (mounted && unlockSuccess) {
        _log.config('applet unlocked');
        state = state?.copyWith(locked: false);
      }
      return Pair(unlockSuccess, false); // TODO: provide correct second param
    } on PlatformException catch (e) {
      _log.info('Calling unlock failed with exception: $e');
      return Pair(false, false);
    }
  }

  @override
  Future<bool> setPassword(String? current, String password) async {
    try {
      if (current != null) {
        await _api.changePassword(current, password);
      } else {
        await _api.setPassword(password);
      }
      return true;
    } on PlatformException catch (e) {
      _log.info('Calling set password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<bool> unsetPassword(String current) async {
    try {
      await _api.unsetPassword(current);
      return true;
    } on PlatformException catch (e) {
      _log.info('Calling unset password failed with exception: $e');
      return false;
    }
  }

  @override
  Future<void> forgetPassword() async {
    try {
      await _api.forgetPassword();
    } on PlatformException catch (e) {
      _log.info('Calling forgetPassword failed with exception: $e');
    }
  }
}

final androidCredentialListProvider = StateNotifierProvider.autoDispose
    .family<OathCredentialListNotifier, List<OathPair>?, DevicePath>(
  (ref, devicePath) {
    var notifier = _AndroidCredentialListNotifier(
      ref.watch(oathApiProvider),
      ref.watch(oathPairsCommandProvider),
      ref.watch(oathStateProvider(devicePath).select((s) => s?.locked ?? true)),
    );
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._notifyWindowState(windowState);
    }, fireImmediately: true);
    return notifier;
  },
);

extension on OathCredential {
  bool get isSteam => issuer == 'Steam' && oathType == OathType.totp;
}

class _AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final OathApi _api;
  final bool _locked;
  Timer? _timer;

  _AndroidCredentialListNotifier(this._api, List<OathPair> pairs, this._locked)
      : super() {
    state = pairs;
    _scheduleRefresh();
  }

  void _notifyWindowState(WindowState windowState) {
    if (_locked) return;
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
      {bool requireTouch = false, bool update = true}) async {
    _log.info('About to add new cred: $credentialUri, $requireTouch, $update');

    String resultString =
        await _api.addAccount(credentialUri.toString(), requireTouch);

    var result = jsonDecode(resultString);
    _log.info('Received credential: $resultString');

    final credential = OathCredential.fromJson(result);

    if (update && mounted) {
      state = state!.toList()..add(OathPair(credential, null));
      if (!requireTouch && credential.oathType == OathType.totp) {
        // TODO handle correctly the account which have been added
        // nfc and usb need different ways
        // don't do: await calculate(credential);
      }
    }

    return credential;
  }

  @override
  Future<OathCredential> renameAccount(
      OathCredential credential, String? issuer, String name) async {
    try {
      String response;
      if (issuer != null) {
        response = await _api.renameAccountWithIssuer(
            credential.id.toString(), name, issuer);
      } else {
        response = await _api.renameAccount(credential.toString(), name);
      }

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
      _log.info('Failed to execute renameOathCredential: ${e.message}');
    }

    return credential;
  }

  @override
  Future<void> deleteAccount(OathCredential credential) async {
    _log.info('About to delete cred: $credential');

    try {
      await _api.deleteAccount(credential.id);

      if (mounted) {
        state = state!.toList()..removeWhere((e) => e.credential == credential);
      }
    } catch (e) {
      _log.info('Call to delete credential failed: $e');
    }
  }

  refresh() async {
    if (_locked) return;
    _log.info('refreshing credentials...');

    final pairs = [];

    try {
      var resultString = await _api.refreshCodes();
      _log.info('Entries', resultString);
      var result = jsonDecode(resultString);

      for (var e in result['entries']) {
        final credential = OathCredential.fromJson(e['credential']);
        final code = e['code'] == null
            ? null
            : credential.isSteam // Steam codes require a re-calculate
                ? await calculate(credential, update: false)
                : OathCode.fromJson(e['code']);
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
      _log.info('Failure refreshing codes: $e');
    }
  }

  _scheduleRefresh() {
    _timer?.cancel();
    if (_locked) return;
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
