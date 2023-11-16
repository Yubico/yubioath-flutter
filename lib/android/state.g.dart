// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
