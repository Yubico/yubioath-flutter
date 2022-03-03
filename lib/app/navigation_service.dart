import 'package:flutter/widgets.dart';

/// Temporary service which is used to get context of the top app widget
/// currently used by nfc operation dialogs
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
