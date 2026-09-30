import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:yubico_authenticator/app/logging.dart';

void main() {
  setUp(() => Logger.root.level = Levels.INFO);
  tearDown(() => Logger.root.level = Levels.INFO);

  test(
    'clears credentials before enabling traffic logging, every time',
    () async {
      final previousLevels = <Level>[];
      final container = ProviderContainer(
        overrides: [
          clearCachedCredentialsProvider.overrideWithValue(() async {
            previousLevels.add(Logger.root.level);
          }),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(logLevelProvider.notifier);

      await notifier.setLogLevel(Levels.DEBUG);
      expect(previousLevels, isEmpty);

      await notifier.setLogLevel(Levels.TRAFFIC);
      expect(previousLevels, [Levels.DEBUG]);
      expect(container.read(logLevelProvider), Levels.TRAFFIC);

      await notifier.setLogLevel(Levels.INFO);
      await notifier.setLogLevel(Levels.TRAFFIC);
      expect(previousLevels, [Levels.DEBUG, Levels.INFO]);
    },
  );

  test('does not enable traffic logging if clearing fails', () async {
    final container = ProviderContainer(
      overrides: [
        clearCachedCredentialsProvider.overrideWithValue(() async {
          throw StateError('credential clearing failed');
        }),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(logLevelProvider.notifier);

    await expectLater(
      notifier.setLogLevel(Levels.TRAFFIC),
      throwsA(isA<StateError>()),
    );
    expect(container.read(logLevelProvider), Levels.INFO);
    expect(Logger.root.level, Levels.INFO);
  });
}
