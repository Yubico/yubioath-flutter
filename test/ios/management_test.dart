import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/app/features.dart' as features;
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
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

  ProviderContainer managementContainer() {
    final path = DevicePath(const []);
    final data = YubiKeyData(
      DeviceNode.nfcReader(path, 'YubiKey'),
      'YubiKey',
      DeviceInfo.fromJson(_deviceInfo),
    );
    final container = ProviderContainer(
      overrides: [
        currentDeviceProvider.overrideWith(_CurrentDevice.new),
        attachedDevicesProvider.overrideWith(_AttachedDevices.new),
        currentDeviceDataProvider.overrideWithValue(AsyncData(data)),
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
        'config': config.toJson(),
        'currentLockCode': '001122',
        'newLockCode': '334455',
        'reboot': true,
      });
    },
  );

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

  testWidgets('NFC discovery opens Home while applets remain placeholders', (
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
    messenger.setMockMethodCallHandler(managementChannel, (call) async {
      expect(call.method, 'readDeviceInfoNfc');
      await messenger.handlePlatformMessage(
        'ios.devices.deviceInfo',
        const StandardMethodCodec().encodeSuccessEnvelope(_deviceInfo),
        (_) {},
      );
      return _deviceInfo;
    });

    await tester.pumpWidget(await ios.initialize());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap your YubiKey'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.byKey(actionsIconButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(yubikeyFactoryResetMenuButton), findsNothing);
    await tester.tap(find.byKey(yubikeyApplicationToggleMenuButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ManagementScreen), findsOneWidget);
    expect(
      container.read(managementStateProvider(DevicePath(const []))),
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
    }
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
