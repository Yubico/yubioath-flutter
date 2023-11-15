// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$androidClipboardHash() => r'9a6b81659fd4968b19180b8451789786ba50dbf7';

/// See also [androidClipboard].
@ProviderFor(androidClipboard)
final androidClipboardProvider = Provider<AppClipboard>.internal(
  androidClipboard,
  name: r'androidClipboardProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$androidClipboardHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AndroidClipboardRef = ProviderRef<AppClipboard>;
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
