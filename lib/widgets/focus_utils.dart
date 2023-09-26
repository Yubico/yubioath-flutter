
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

import '../app/logging.dart';

final _log = Logger('FocusUtils');

class FocusUtils {
  static void unfocus(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      _log.debug('Removing focus...');
      currentFocus.unfocus();
    }
  }
}