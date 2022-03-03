import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/models.dart';
import '../app/state.dart';
import 'api/flutter_management_api_impl.dart';
import 'api/flutter_oath_api_impl.dart';
import 'api/impl.dart';
import 'command_providers.dart';

final androidSubPageProvider = StateNotifierProvider<SubPageNotifier, SubPage>(
    (ref) => AndroidSubPageNotifier(ref));

class AndroidSubPageNotifier extends SubPageNotifier {
  StateNotifierProviderRef ref;
  final AppApi _api = AppApi();

  AndroidSubPageNotifier(this.ref) : super(SubPage.oath) {
    // TODO find more appropriate place where to setup these api's
    FOathApi.setup(FOathApiImpl(ref));
    FManagementApi.setup(FManagementApiImpl(ref));

    _handleSubPage(SubPage.oath);
  }

  @override
  void setSubPage(SubPage page) {
    super.setSubPage(page);
    _handleSubPage(page);
  }

  void _handleSubPage(SubPage subPage) async {
    await _api.setContext(subPage.index);
  }
}

final androidAttachedDevicesProvider = Provider<List<DeviceNode>>((ref) {
  var currentDeviceData = ref.watch(androidDeviceDataProvider);
  if (currentDeviceData != null) {
    return [currentDeviceData.node];
  }
  return [];
});

final androidDeviceDataProvider =
    Provider<YubiKeyData?>((ref) => ref.watch(yubikeyDataCommandProvider));
