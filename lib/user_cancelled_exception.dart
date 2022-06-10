import 'package:flutter/services.dart';

class UserCancelledException implements Exception {
  UserCancelledException();

  static isCancellation(PlatformException pe) =>
    pe.code == 'UserCancelledException';

}
