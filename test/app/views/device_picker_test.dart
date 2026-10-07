import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yubico_authenticator/app/models.dart';
import 'package:yubico_authenticator/app/state.dart';
import 'package:yubico_authenticator/app/views/device_avatar.dart';
import 'package:yubico_authenticator/app/views/device_picker.dart';
import 'package:yubico_authenticator/app/views/navigation.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/desktop/state.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations.dart';
import 'package:yubico_authenticator/generated/l10n/app_localizations_en.dart';
import 'package:yubico_authenticator/theme.dart';

class _NoDevices extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => [];
}

final _reader = DeviceNode.yubiKey(
  DevicePath(['devices', 'reader']),
  'NFC reader',
  null,
  Transport.nfc,
  null,
);

class _ReaderDevices extends AttachedDevicesNotifier {
  @override
  List<DeviceNode> build() => [_reader];
}

class _NoCurrentDevice extends CurrentDeviceNotifier {
  @override
  DeviceNode? build() => null;

  @override
  void setCurrentDevice(DeviceNode? device) => state = device;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();
  late SharedPreferences prefs;

  setUpAll(() async {
    final fonts = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await fonts.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    required bool extended,
    bool isDrawer = false,
    bool referenceRow = false,
    bool reader = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefProvider.overrideWithValue(prefs),
          attachedDevicesProvider.overrideWith(
            reader ? _ReaderDevices.new : _NoDevices.new,
          ),
          currentDeviceProvider.overrideWith(_NoCurrentDevice.new),
          currentDeviceDataProvider.overrideWithValue(const AsyncLoading()),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(defaultPrimaryColor),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: Column(
                children: [
                  DevicePickerContent(extended: extended, isDrawer: isDrawer),
                  if (referenceRow)
                    DeviceRow(
                      key: const Key('connected-key-row'),
                      leading: const CircleAvatar(
                        child: Icon(Symbols.security_key),
                      ),
                      title: 'YubiKey 5C NFC',
                      subtitle: 'S/N: 1234 F/W: 5.2.6',
                      extended: true,
                      selected: true,
                      onTap: () {},
                    ),
                  if (referenceRow)
                    NavigationItem(
                      leading: const Icon(Symbols.home),
                      title: l10n.s_home,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'previously hidden reader can be restored as the current device',
    () async {
      await prefs.setStringList('DEVICE_PICKER_HIDDEN', [_reader.path.key]);
      await prefs.setString('APP_STATE_LAST_DEVICE', _reader.path.key);
      final container = ProviderContainer(
        overrides: [
          prefProvider.overrideWithValue(prefs),
          attachedDevicesProvider.overrideWith(_ReaderDevices.new),
          currentDeviceProvider.overrideWith(DesktopCurrentDeviceNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentDeviceProvider), _reader);
    },
  );

  for (final extended in [false, true]) {
    testWidgets(
      'previously hidden reader is visible without reader menus (extended=$extended)',
      (tester) async {
        await prefs.setStringList('DEVICE_PICKER_HIDDEN', [_reader.path.key]);
        await pumpPicker(tester, extended: extended, reader: true);

        final row = find.byKey(ValueKey(_reader.path.key));
        expect(row, findsOneWidget);
        expect(find.byType(PopupMenuButton), findsNothing);
        expect(find.byIcon(Symbols.more_horiz), findsNothing);
        await tester.longPress(row);
        await tester.pumpAndSettle();
        expect(find.byType(PopupMenuItem), findsNothing);

        await tester.tap(row);
        final container = ProviderScope.containerOf(tester.element(row));
        expect(container.read(currentDeviceProvider), _reader);
      },
      variant: TargetPlatformVariant({TargetPlatform.linux}),
    );
  }

  for (final scale in [0.8, 1.5, 2.0]) {
    testWidgets('empty row matches Home with text scale $scale', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        extended: true,
        referenceRow: true,
        textScale: scale,
      );
      final emptyTile = find.descendant(
        of: find.byType(DevicePickerContent),
        matching: find.byType(ListTile),
      );
      final homeTile = find.descendant(
        of: find.byType(NavigationItem),
        matching: find.byType(ListTile),
      );
      expect(tester.getSize(emptyTile).height, tester.getSize(homeTile).height);
      expect(
        tester.getCenter(find.text(l10n.l_no_yk_present)).dy,
        closeTo(tester.getCenter(emptyTile).dy, 0.5),
      );
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  }

  for (final isDrawer in [false, true]) {
    testWidgets(
      'empty navigation is a centered single-line row (drawer=$isDrawer)',
      (tester) async {
        await pumpPicker(
          tester,
          extended: true,
          isDrawer: isDrawer,
          referenceRow: true,
        );
        expect(find.text(l10n.s_usb), findsNothing);
        expect(find.text(l10n.l_no_yk_present), findsOneWidget);
        expect(find.byIcon(Symbols.usb), findsNothing);
        final emptyTile = find.descendant(
          of: find.byType(DevicePickerContent),
          matching: find.byType(ListTile),
        );
        final connectedTile = find.descendant(
          of: find.byKey(const Key('connected-key-row')),
          matching: find.byType(ListTile),
        );
        final homeTile = find.descendant(
          of: find.byType(NavigationItem),
          matching: find.byType(ListTile),
        );
        final tile = tester.widget<ListTile>(emptyTile);
        expect(tile.subtitle, isNull);
        expect(tile.dense, isFalse);
        expect(tester.widget<ListTile>(connectedTile).dense, isTrue);
        final placeholderText = find.text(l10n.l_no_yk_present);
        final homeText = find.text(l10n.s_home);
        TextStyle effectiveStyle(Finder finder) {
          final text = tester.widget<Text>(finder);
          return DefaultTextStyle.of(tester.element(finder)).style
              .merge(text.style);
        }

        expect(
          effectiveStyle(placeholderText).fontSize,
          effectiveStyle(homeText).fontSize,
        );
        expect(
          effectiveStyle(placeholderText).color,
          effectiveStyle(find.text('YubiKey 5C NFC')).color,
        );
        expect(
          tester.getSize(emptyTile).height,
          tester.getSize(homeTile).height,
        );
        expect(
          tester.getCenter(find.text(l10n.l_no_yk_present)).dy,
          closeTo(tester.getCenter(emptyTile).dy, 0.5),
        );
        final placeholderIcon = find.descendant(
          of: find.byType(DeviceAvatar),
          matching: find.byIcon(Symbols.security_key),
        );
        expect(placeholderIcon, findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(
          IconTheme.of(tester.element(placeholderIcon)).color,
          effectiveStyle(placeholderText).color,
        );
      },
      variant: TargetPlatformVariant({TargetPlatform.linux}),
    );
  }

  testWidgets(
    'collapsed navigation uses the security key icon and no USB label',
    (tester) async {
      await pumpPicker(tester, extended: false);
      expect(find.byIcon(Symbols.usb), findsNothing);
      expect(find.byIcon(Symbols.security_key), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byTooltip(l10n.l_no_yk_present), findsOneWidget);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
