import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/oath/state.dart';

import '../../app/views/user_interaction.dart';
import '../../cancellation_exception.dart';
import '../../oath/models.dart';

final _log = Logger('android.oath.state');

const _channel = MethodChannel('com.yubico.authenticator.channel.oath');

final _oathDataProvider =
    StateNotifierProvider<_OathDataProvider, Pair<OathState?, List<OathPair>?>>(
  (ref) {
    // Reset on device change
    ref.watch(currentDeviceProvider);
    return _OathDataProvider();
  },
);

class _OathDataProvider
    extends StateNotifier<Pair<OathState?, List<OathPair>?>> {
  _OathDataProvider() : super(Pair(null, null)) {
    _channel.setMethodCallHandler((call) async {
      final json = jsonDecode(call.arguments);
      switch (call.method) {
        case 'setState':
          state = state.copyWith(first: OathState.fromJson(json));
          break;
        case 'setCredentials':
          List<OathPair> pairs =
              (json as List).map((e) => OathPair.fromJson(e)).toList();
          state = state.copyWith(second: pairs);
          break;
        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}

final androidOathStateProvider = StateNotifierProvider.autoDispose
    .family<OathStateNotifier, AsyncValue<OathState>, DevicePath>(
        (ref, devicePath) => _AndroidOathStateNotifier(
            ref.watch(_oathDataProvider.select((pair) => pair.first))));

class _AndroidOathStateNotifier extends OathStateNotifier {
  _AndroidOathStateNotifier(OathState? value) : super() {
    if (value != null) {
      setData(value);
    }
  }

  @override
  Future<void> reset() async {
    try {
      await _channel.invokeMethod('reset');
    } catch (e) {
      _log.debug('Calling reset failed with exception: $e');
    }
  }

  @override
  Future<Pair<bool, bool>> unlock(String password,
      {bool remember = false}) async {
    try {
      final unlockResponse = jsonDecode(await _channel.invokeMethod(
          'unlock', {'password': password, 'remember': remember}));

      final unlocked = unlockResponse['unlocked'] == true;
      final remembered = unlockResponse['emembered'] == true;

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
      await _channel.invokeMethod(
          'setPassword', {'current': current, 'password': password});
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
      await _channel.invokeMethod('unsetPassword', {'current': current});
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
      await _channel.invokeMethod('forgetPassword');
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
      ref.watch(withContextProvider),
      ref.watch(currentDeviceProvider),
      ref.watch(_oathDataProvider.select((pair) => pair.second)),
    );
    ref.listen<WindowState>(windowStateProvider, (_, windowState) {
      notifier._notifyWindowState(windowState);
    }, fireImmediately: true);
    return notifier;
  },
);

class _AndroidCredentialListNotifier extends OathCredentialListNotifier {
  final WithContext _withContext;
  final DeviceNode? _currentDevice;
  Timer? _timer;

  _AndroidCredentialListNotifier(
      this._withContext, this._currentDevice, List<OathPair>? value)
      : super() {
    state = value;
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
    // Prompt for touch if needed
    UserInteractionController? controller;
    Timer? touchTimer;
    if (_currentDevice?.transport == Transport.usb) {
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
      var resultJson = await _channel
          .invokeMethod('calculate', {'credentialId': credential.id});
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
    } finally {
      touchTimer?.cancel();
      controller?.close();
    }
  }

  @override
  Future<OathCredential> addAccount(Uri credentialUri,
      {bool requireTouch = false}) async {
    try {
      String resultString = await _channel.invokeMethod('addAccount',
          {'uri': credentialUri.toString(), 'requireTouch': requireTouch});

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
      response = await _channel.invokeMethod('renameAccount',
          {'credentialId': credential.id, 'name': name, 'issuer': issuer});

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
      await _channel
          .invokeMethod('deleteAccount', {'credentialId': credential.id});

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
      var resultString = await _channel.invokeMethod('refreshCodes');
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
