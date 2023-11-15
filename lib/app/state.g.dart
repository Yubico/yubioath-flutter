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
String _$supportedThemesHash() => r'bc21b04f22a67450eba0e1cf08c86aa1feb23614';

/// See also [supportedThemes].
@ProviderFor(supportedThemes)
final supportedThemesProvider = Provider<List<ThemeMode>>.internal(
  supportedThemes,
  name: r'supportedThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedThemesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SupportedThemesRef = ProviderRef<List<ThemeMode>>;
String _$supportedLocalesHash() => r'db5301530aa7ade608e515b86b1488b65cd09ea2';

/// See also [supportedLocales].
@ProviderFor(supportedLocales)
final supportedLocalesProvider = Provider<List<Locale>>.internal(
  supportedLocales,
  name: r'supportedLocalesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedLocalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SupportedLocalesRef = ProviderRef<List<Locale>>;
String _$currentLocaleHash() => r'dd59a8d8f6a59f1fa3bc965b9a10d88e67589bf6';

/// See also [currentLocale].
@ProviderFor(currentLocale)
final currentLocaleProvider = Provider<Locale>.internal(
  currentLocale,
  name: r'currentLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocaleHash,
  dependencies: null,
  allTransitiveDependencies: null,
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
String _$currentDeviceDataHash() => r'ea4ebb353bd875ed9b128692ad468b6a10ea479e';

/// See also [currentDeviceData].
@ProviderFor(currentDeviceData)
final currentDeviceDataProvider = Provider<AsyncValue<YubiKeyData>>.internal(
  currentDeviceData,
  name: r'currentDeviceDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeviceDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
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
String _$clipboardHash() => r'ba2d4329370e3b6e8ec190332872634948446851';

/// See also [clipboard].
@ProviderFor(clipboard)
final clipboardProvider = Provider<AppClipboard>.internal(
  clipboard,
  name: r'clipboardProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$clipboardHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ClipboardRef = ProviderRef<AppClipboard>;
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
    r'84a33fe183c4f75b345b501f7b739e5d70643341';

/// See also [CommunityTranslations].
@ProviderFor(CommunityTranslations)
final communityTranslationsProvider =
    NotifierProvider<CommunityTranslations, bool>.internal(
  CommunityTranslations.new,
  name: r'communityTranslationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$communityTranslationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommunityTranslations = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
