import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/android/logger.dart';
import 'package:yubico_authenticator/app/logging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('android.log.redirect');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => Logger.root.level = Levels.INFO);
  tearDown(() {
    Logger.root.level = Levels.INFO;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('native traffic level changes before Dart traffic logging', () async {
    final requested = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setLevel') {
        expect(Logger.root.level, Levels.INFO);
        requested.add(call.arguments['level'] as String);
      }
      return null;
    });

    final logger = AndroidLogger();
    addTearDown(logger.dispose);
    await logger.setLogLevel(Levels.TRAFFIC);

    expect(requested, ['TRAFFIC']);
    expect(Logger.root.level, Levels.TRAFFIC);
  });

  test('native failure leaves Dart traffic logging disabled', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setLevel') {
        throw PlatformException(code: 'clear-failed');
      }
      return null;
    });

    final logger = AndroidLogger();
    addTearDown(logger.dispose);
    await expectLater(
      logger.setLogLevel(Levels.TRAFFIC),
      throwsA(isA<PlatformException>()),
    );
    expect(Logger.root.level, Levels.INFO);
  });
}
