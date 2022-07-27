import 'package:pigeon/pigeon.dart';

class UnlockResponse {
  bool? isUnlocked;
  bool? isRemembered;
}

@HostApi()
abstract class OathApi {
  @async
  void reset();

  @async
  UnlockResponse unlock(String password, bool remember);

  @async
  void setPassword(String? currentPassword, String newPassword);

  @async
  void unsetPassword(String currentPassword);

  @async
  void forgetPassword();

  @async
  String addAccount(String uri, bool requireTouch);

  @async
  String renameAccount(String uri, String name, String? issuer);

  @async
  void deleteAccount(String uri);

  @async
  String refreshCodes();

  @async
  String calculate(String uri);
}

@HostApi()
abstract class AppApi {
  @async
  void setContext(int subPageIndex);
}

@FlutterApi()
abstract class FOathApi {
  @async
  void updateSession(String sessionJson);

  @async
  void updateOathCredentials(String credentialListJson);
}

@FlutterApi()
abstract class FManagementApi {
  @async
  void updateDeviceInfo(String deviceInfoJson);
}

@FlutterApi()
abstract class FDialogApi {
  @async
  void showDialog(String dialogMessage);

  void updateDialogState(String? title, String? description, String? icon);

  void closeDialog();
}

@HostApi()
abstract class HDialogApi {
  @async
  void dialogClosed();
}
