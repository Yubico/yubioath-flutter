import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/device_picker.dart';

import '../../integration_test/utils.dart';

void main() {
  patrolWidgetTest('missing USB YubiKey fails after five seconds', ($) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            currentDeviceDataProvider.overrideWithValue(const AsyncLoading()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DeviceRow(
                leading: const Icon(Icons.usb),
                title: 'No YubiKey present',
                extended: true,
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await $.tester.runAsync(() async {
        final elapsed = Stopwatch()..start();
        TestFailure? failure;
        try {
          await $.waitForYubiKey();
        } on TestFailure catch (error) {
          failure = error;
        }
        expect(
          failure,
          isA<TestFailure>().having(
            (error) => error.message,
            'message',
            'No YubiKey became available within 5 seconds',
          ),
        );
        expect(
          elapsed.elapsed,
          greaterThanOrEqualTo(const Duration(seconds: 5)),
        );
        expect(elapsed.elapsed, lessThan(const Duration(seconds: 7)));
      });
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
