import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/android/init.dart' as android;
import 'package:yubico_authenticator/app/views/device_button.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/init.dart' as desktop;

Future<Widget> getAuthenticatorApp() async => isDesktop
    ? await desktop.initialize([])
    : isAndroid
        ? await android.initialize()
        : throw UnimplementedError('Platform not supported');

extension TestHelper on WidgetTester {
  /// Taps the device button
  Future<void> tapDeviceButton() async {
    await tap(find.byType(DeviceButton));
    await pump(const Duration(milliseconds: 500));
  }

  Future<void> startUp() async {
    await pumpWidget(
        await getAuthenticatorApp(), const Duration(milliseconds: 2000));
  }
}
