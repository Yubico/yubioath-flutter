import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/desktop/init.dart';

Future<void> startUp(WidgetTester tester,
        [Map<dynamic, dynamic>? startUpParams]) async =>
    tester.pumpWidget(await initialize([]), const Duration(milliseconds: 2000));
