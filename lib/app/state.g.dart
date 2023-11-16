// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$windowStateHash() => r'2128c6667d7e69b544c74ef2372c70ff17fa7174';

/// See also [windowState].
@ProviderFor(windowState)
final windowStateProvider = Provider<WindowState>.internal(
  windowState,
  name: r'windowStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$windowStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WindowStateRef = ProviderRef<WindowState>;
String _$supportedThemesHash() => r'0499ad1ad4965dd63251e525b2662241c458cac9';

/// See also [supportedThemes].
@ProviderFor(supportedThemes)
final supportedThemesProvider = Provider<List<ThemeMode>>.internal(
  supportedThemes,
  name: r'supportedThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedThemesHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

typedef SupportedThemesRef = ProviderRef<List<ThemeMode>>;
String _$supportedLocalesHash() => r'38fd408b4f3fc35568f1b036ea91b1cc23ededa6';

/// See also [supportedLocales].
@ProviderFor(supportedLocales)
final supportedLocalesProvider = Provider<List<Locale>>.internal(
  supportedLocales,
  name: r'supportedLocalesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedLocalesHash,
  dependencies: <ProviderOrFamily>[communityTranslationsProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    communityTranslationsProvider,
    ...?communityTranslationsProvider.allTransitiveDependencies
  },
);

typedef SupportedLocalesRef = ProviderRef<List<Locale>>;
String _$currentLocaleHash() => r'6073128c053e5e4546320acdd7239fa20832411a';

/// See also [currentLocale].
@ProviderFor(currentLocale)
final currentLocaleProvider = Provider<Locale>.internal(
  currentLocale,
  name: r'currentLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocaleHash,
  dependencies: <ProviderOrFamily>[supportedLocalesProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    supportedLocalesProvider,
    ...?supportedLocalesProvider.allTransitiveDependencies
  },
);

typedef CurrentLocaleRef = ProviderRef<Locale>;
String _$l10nHash() => r'fc7c0fbb213ed7b5272dc8096119f1dc1eadf8fd';

/// See also [l10n].
@ProviderFor(l10n)
final l10nProvider = Provider<AppLocalizations>.internal(
  l10n,
  name: r'l10nProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$l10nHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef L10nRef = ProviderRef<AppLocalizations>;
String _$currentDeviceDataHash() => r'6ec053541579722e386fcf28bae998d7a001d404';

/// See also [currentDeviceData].
@ProviderFor(currentDeviceData)
final currentDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>.internal(
  currentDeviceData,
  name: r'currentDeviceDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeviceDataHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

typedef CurrentDeviceDataRef = ProviderRef<AsyncValue<YubiKeyData>>;
String _$qrScannerHash() => r'd6cce8d391bbb99d38c6a8a8084470c0dde12bb8';

/// See also [qrScanner].
@ProviderFor(qrScanner)
final qrScannerProvider = Provider<QrScanner?>.internal(
  qrScanner,
  name: r'qrScannerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$qrScannerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef QrScannerRef = ProviderRef<QrScanner?>;
String _$withContextHash() => r'de4a8eda3ee29ae2d07c5e55a1923dab291a9e66';

/// See also [withContext].
@ProviderFor(withContext)
final withContextProvider = Provider<WithContext>.internal(
  withContext,
  name: r'withContextProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$withContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WithContextRef = ProviderRef<WithContext>;
String _$communityTranslationsHash() =>
    r'9dd535f5c7c38f3d6748c978e811fa3424f7d856';

/// See also [CommunityTranslations].
@ProviderFor(CommunityTranslations)
final communityTranslationsProvider =
    NotifierProvider<CommunityTranslations, bool>.internal(
  CommunityTranslations.new,
  name: r'communityTranslationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$communityTranslationsHash,
  dependencies: <ProviderOrFamily>[prefProvider],
  allTransitiveDependencies: <ProviderOrFamily>{
    prefProvider,
    ...?prefProvider.allTransitiveDependencies
  },
);

typedef _$CommunityTranslations = Notifier<bool>;
String _$appClipboardHash() => r'348743f64c544642c64a9afcb508ece82e6775a2';

/// See also [AppClipboard].
@ProviderFor(AppClipboard)
final appClipboardProvider = NotifierProvider<AppClipboard, void>.internal(
  AppClipboard.new,
  name: r'appClipboardProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appClipboardHash,
  dependencies: const <ProviderOrFamily>[],
  allTransitiveDependencies: const <ProviderOrFamily>{},
);

typedef _$AppClipboard = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
