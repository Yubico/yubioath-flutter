// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$desktopSupportedThemesHash() =>
    r'e80e2d56110b0e266f7fee3b4f40d1c7bdebdb53';

/// See also [desktopSupportedThemes].
@ProviderFor(desktopSupportedThemes)
final desktopSupportedThemesProvider = Provider<List<ThemeMode>>.internal(
  desktopSupportedThemes,
  name: r'desktopSupportedThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$desktopSupportedThemesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DesktopSupportedThemesRef = ProviderRef<List<ThemeMode>>;
String _$rpcHash() => r'a86bed0bcfc26b818457042a388f4663b1149542';

/// See also [Rpc].
@ProviderFor(Rpc)
final rpcProvider = AsyncNotifierProvider<Rpc, RpcSession>.internal(
  Rpc.new,
  name: r'rpcProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rpcHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Rpc = AsyncNotifier<RpcSession>;
String _$asyncRpcStateHash() => r'cf1cc3c661c1356f93d429a9bd9791909d24cf5c';

/// See also [AsyncRpcState].
@ProviderFor(AsyncRpcState)
final asyncRpcStateProvider =
    NotifierProvider<AsyncRpcState, RpcState>.internal(
  AsyncRpcState.new,
  name: r'asyncRpcStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncRpcStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncRpcState = Notifier<RpcState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
