import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/app/features.dart' as features;
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/ios/init.dart' as ios;
import 'package:yubico_authenticator/ios/management/state.dart';
import 'package:yubico_authenticator/ios/state.dart';
import 'package:yubico_authenticator/management/models.dart';
import 'package:yubico_authenticator/management/state.dart';
import 'package:yubico_authenticator/management/views/management_screen.dart';

final _deviceInfo = <String, Object?>{
  'config': {
    'enabled_capabilities': {'usb': 63, 'nfc': 63},
  },
  'version': [5, 7, 4],
  'serial': 123456,
  'form_factor': 1,
  'supported_capabilities': {'usb': 63, 'nfc': 63},
  'is_locked': false,
  'is_fips': false,
  'is_sky': false,
  'pin_complexity': false,
  'fips_capable': 0,
  'fips_approved': 0,
  'reset_blocked': 0,
  'version_qualifier': {
    'version': [5, 7, 4],
    'type': 2,
    'iteration': 0,
  },
  'name': 'YubiKey',
  'is_nfc': true,
};

final _displayedData = StateProvider<AsyncValue<YubiKeyData>>(
  (ref) => const AsyncLoading(),
);

class _CurrentDevice extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() => null;

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

class _AttachedDevices extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(managementChannel, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('ios.devices.deviceInfo'),
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  ProviderContainer managementContainer({
    Map<String, Object?>? deviceInfo,
    bool wired = false,
  }) {
    final path = DevicePath(const []);
    final info = DeviceInfo.fromJson(deviceInfo ?? _deviceInfo);
    final data = YubiKeyData(
      wired
          ? DeviceNode.usbYubiKey(path, 'YubiKey', UsbPid.yk4OtpFidoCcid, info)
          : DeviceNode.nfcReader(path, 'YubiKey'),
      'YubiKey',
      info,
    );
    final container = ProviderContainer(
      overrides: [
        currentDeviceProvider.overrideWith(_CurrentDevice.new),
        attachedDevicesProvider.overrideWith(_AttachedDevices.new),
        _displayedData.overrideWith((ref) => AsyncData(data)),
        currentDeviceDataProvider.overrideWith(
          (ref) => ref.watch(_displayedData),
        ),
        managementStateProvider.overrideWith2(IosManagementStateNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'management forwards configuration and reset to the native channel',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(managementChannel, (call) async {
        calls.add(call);
        return null;
      });
      final container = managementContainer();
      final path = DevicePath(const []);
      final subscription = container.listen(
        managementStateProvider(path),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(managementStateProvider(path).future);
      final notifier = container.read(managementStateProvider(path).notifier);
      final config = DeviceInfo.fromJson(_deviceInfo).config;

      await notifier.writeConfig(
        config,
        currentLockCode: '001122',
        newLockCode: '334455',
        reboot: true,
      );
      await notifier.deviceReset();

      expect(calls.map((call) => call.method), ['configure', 'deviceReset']);
      expect(calls.first.arguments, {
        'expectedDevice': {
          'transport': 'nfc',
          'serial': 123456,
          'version': [5, 7, 4],
          'formFactor': 1,
          'supportedCapabilities': {'usb': 63, 'nfc': 63},
          'isFips': false,
          'isSky': false,
        },
        'config': config.toJson(),
        'currentLockCode': '001122',
        'newLockCode': '334455',
        'reboot': true,
      });
      expect(calls.last.arguments, {
        'expectedDevice': (calls.first.arguments as Map)['expectedDevice'],
      });
    },
  );

  test('wired operations keep their target transport', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(managementChannel, (call) async {
      calls.add(call);
      return null;
    });
    final container = managementContainer(wired: true);
    final path = DevicePath(const []);
    final subscription = container.listen(
      managementStateProvider(path),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(managementStateProvider(path).future);
    await container.read(managementStateProvider(path).notifier).deviceReset();
    expect(
      (calls.single.arguments as Map)['expectedDevice']['transport'],
      'usb',
    );
  });

  test(
    'serial-less keys send metadata instead of an invented identity',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(managementChannel, (call) async {
        calls.add(call);
        return null;
      });
      final container = managementContainer(
        deviceInfo: {..._deviceInfo, 'serial': null},
      );
      final path = DevicePath(const []);
      final subscription = container.listen(
        managementStateProvider(path),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(managementStateProvider(path).future);
      await container
          .read(managementStateProvider(path).notifier)
          .deviceReset();
      final expected = (calls.single.arguments as Map)['expectedDevice'] as Map;
      expect(expected['serial'], isNull);
      expect(expected['version'], [5, 7, 4]);
      expect(expected['supportedCapabilities'], {'usb': 63, 'nfc': 63});
    },
  );

  test('a changed displayed key cannot retarget an open operation', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(managementChannel, (call) async {
      calls.add(call);
      return null;
    });
    final container = managementContainer();
    final path = DevicePath(const []);
    final subscription = container.listen(
      managementStateProvider(path),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(managementStateProvider(path).future);
    final notifier = container.read(managementStateProvider(path).notifier);
    final info = DeviceInfo.fromJson({..._deviceInfo, 'serial': 987654});
    container.read(_displayedData.notifier).state = AsyncData(
      YubiKeyData(
        DeviceNode.nfcReader(DevicePath(['ios', 'nfc', '987654']), 'YubiKey'),
        'YubiKey',
        info,
      ),
    );
    await expectLater(
      notifier.writeConfig(info.config),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'device_changed',
        ),
      ),
    );
    await expectLater(
      notifier.deviceReset(),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'device_changed',
        ),
      ),
    );
    expect(calls, isEmpty);
  });

  test('management surfaces native failures', () async {
    messenger.setMockMethodCallHandler(managementChannel, (call) async {
      throw PlatformException(code: 'unsupported', message: 'Not supported');
    });
    final container = managementContainer();
    final path = DevicePath(const []);
    final subscription = container.listen(
      managementStateProvider(path),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(managementStateProvider(path).future);

    await expectLater(
      container
          .read(managementStateProvider(path).notifier)
          .setMode(interfaces: 7),
      throwsA(isA<PlatformException>()),
    );
  });

  testWidgets('pulling Home scans NFC with and without a displayed key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(
      const MethodChannel('ios.devices.deviceInfo'),
      (call) async => null,
    );
    var scanCount = 0;
    messenger.setMockMethodCallHandler(managementChannel, (call) async {
      expect(call.method, 'readDeviceInfoNfc');
      scanCount++;
      await messenger.handlePlatformMessage(
        'ios.devices.deviceInfo',
        const StandardMethodCodec().encodeSuccessEnvelope(_deviceInfo),
        (_) {},
      );
      return _deviceInfo;
    });

    await tester.pumpWidget(await ios.initialize());
    await tester.pumpAndSettle();
    expect(find.text('Tap your YubiKey'), findsNothing);
    await tester.drag(
      find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(scanCount, 1);

    expect(find.text('YubiKey'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('YubiKey')),
    );
    expect(
      container.read(currentDeviceDataProvider).value?.info.serial,
      123456,
    );
    expect(container.read(featureProvider)(features.management), isTrue);
    expect(container.read(featureProvider)(features.oath), isFalse);
    expect(container.read(featureProvider)(features.fido), isFalse);
    expect(container.read(featureProvider)(features.piv), isFalse);

    await tester.drag(
      find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(scanCount, 2);

    await tester.tap(find.byKey(actionsIconButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(yubikeyFactoryResetMenuButton), findsNothing);
    await tester.tap(find.byKey(yubikeyApplicationToggleMenuButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ManagementScreen), findsOneWidget);
    expect(
      container.read(
        managementStateProvider(
          container.read(currentDeviceDataProvider).value!.node.path,
        ),
      ),
      isA<AsyncData<DeviceInfo>>(),
    );
    await tester.tap(find.byKey(closeButton));
    await tester.pumpAndSettle();

    for (final section in [
      Section.accounts,
      Section.passkeys,
      Section.certificates,
      Section.slots,
      Section.settings,
    ]) {
      container
          .read(currentSectionProvider.notifier)
          .setCurrentSection(section);
      await tester.pumpAndSettle();
      expect(find.text('Currently not implemented'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsNothing);
    }
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
