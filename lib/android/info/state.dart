import 'package:logging/logging.dart';

import '../command_providers.dart';
import '../init.dart';

final log = Logger('android.info.state');

void setupInfoPageMethodChannel(ref) {
  methodChannel.setMethodCallHandler((call) async {
    log.info('Received: $call');
    switch (call.method) {
      case 'deviceInfo':
        ref.read(yubikeyDataCommandProvider.notifier).set(call.arguments);
        break;
    }
  });
}
