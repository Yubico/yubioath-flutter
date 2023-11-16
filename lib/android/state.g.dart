// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$androidSdkVersionHash() => r'd69b669a678fa3d1e516fcc963236af7d5943b77';

/// See also [androidSdkVersion].
@ProviderFor(androidSdkVersion)
final androidSdkVersionProvider = Provider<int>.internal(
  androidSdkVersion,
  name: r'androidSdkVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$androidSdkVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AndroidSdkVersionRef = ProviderRef<int>;
String _$androidNfcSupportHash() => r'c4a122eb3ffab69220205e7b21937ae9dcb6a4ce';

/// See also [androidNfcSupport].
@ProviderFor(androidNfcSupport)
final androidNfcSupportProvider = Provider<bool>.internal(
  androidNfcSupport,
  name: r'androidNfcSupportProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$androidNfcSupportHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AndroidNfcSupportRef = ProviderRef<bool>;
String _$androidSupportedThemesHash() =>
    r'b37850e8e4b37f934074472e75d4b354433b943c';

/// See also [androidSupportedThemes].
@ProviderFor(androidSupportedThemes)
final androidSupportedThemesProvider = Provider<List<ThemeMode>>.internal(
  androidSupportedThemes,
  name: r'androidSupportedThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$androidSupportedThemesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AndroidSupportedThemesRef = ProviderRef<List<ThemeMode>>;
String _$androidAllowScreenshotsHash() =>
    r'29489e7a1bf79d4c2b35c3da17958aafca8ced35';

/// See also [AndroidAllowScreenshots].
@ProviderFor(AndroidAllowScreenshots)
final androidAllowScreenshotsProvider =
    NotifierProvider<AndroidAllowScreenshots, bool>.internal(
  AndroidAllowScreenshots.new,
  name: r'androidAllowScreenshotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$androidAllowScreenshotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AndroidAllowScreenshots = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
