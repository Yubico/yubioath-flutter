import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/desktop/credential_cache.dart';

void main() {
  testWidgets('expires at exactly three minutes without a read', (
    tester,
  ) async {
    final credential = CachedCredential();
    addTearDown(credential.dispose);
    String? observed;
    credential.addListener((value) => observed = value);
    credential.value = 'secret';

    await tester.pump(
      const Duration(minutes: 3) - const Duration(microseconds: 1),
    );
    expect(observed, 'secret');
    await tester.pump(const Duration(microseconds: 1));
    expect(observed, isNull);
    expect(credential.value, isNull);
  });

  testWidgets('retrieving a credential renews its idle deadline', (
    tester,
  ) async {
    var now = DateTime(2026);
    final credential = CachedCredential(now: () => now);
    addTearDown(credential.dispose);
    String? observed;
    credential.addListener((value) => observed = value);
    credential.value = 'secret';

    final interval =
        const Duration(minutes: 3) - const Duration(microseconds: 1);
    now = now.add(interval);
    await tester.pump(interval);
    expect(credential.value, 'secret');

    now = now.add(interval);
    await tester.pump(interval);
    expect(observed, 'secret');
    await tester.pump(const Duration(microseconds: 1));
    expect(observed, isNull);
  });

  testWidgets('a delayed timer cannot return or revive an expired credential', (
    tester,
  ) async {
    for (final idle in [
      const Duration(minutes: 3),
      const Duration(minutes: 3, microseconds: 1),
      const Duration(hours: 1),
    ]) {
      var now = DateTime(2026);
      final credential = CachedCredential(now: () => now);
      credential.value = 'secret';
      now = now.add(idle);
      expect(credential.value, isNull);
      expect(credential.value, isNull);
      credential.dispose();
    }
  });

  testWidgets('replacement starts a fresh timeout and clearing cancels it', (
    tester,
  ) async {
    final credential = CachedCredential();
    addTearDown(credential.dispose);
    final changes = <String?>[];
    credential.addListener(changes.add);
    credential.value = 'old';
    await tester.pump(const Duration(minutes: 2));
    credential.value = 'new';
    await tester.pump(const Duration(minutes: 1));
    expect(changes.last, 'new');
    credential.value = null;
    final count = changes.length;
    await tester.pump(const Duration(minutes: 3));
    expect(changes.length, count);
    expect(credential.value, isNull);
  });

  testWidgets('accessing one credential does not extend another', (
    tester,
  ) async {
    var now = DateTime(2026);
    final first = CachedCredential(now: () => now);
    final second = CachedCredential(now: () => now);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    String? secondValue;
    second.addListener((value) => secondValue = value);
    first.value = 'first';
    second.value = 'second';

    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(first.value, 'first');
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(first.value, 'first');
    expect(secondValue, isNull);
    first.value = null;
  });

  testWidgets('disposal cancels pending expiry', (tester) async {
    final credential = CachedCredential();
    credential.value = 'secret';
    credential.dispose();
    await tester.pump(const Duration(minutes: 3));
  });
}
