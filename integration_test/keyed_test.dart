import 'oath_test.dart' as oath;

const testApps = String.fromEnvironment('TEST_APPS');

const tests = {'oath': oath.main};

void main() {
  // Collects all the keyed tests and runs them
  if (testApps.isEmpty) {
    for (final test in tests.values) {
      test();
    }
  } else {
    // Run only the specified apps
    for (final name in testApps.split(',')) {
      tests[name]!();
    }
  }
}
