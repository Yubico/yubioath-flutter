import 'fido_test.dart' as fido;
import 'oath_test.dart' as oath;
import 'otp_test.dart' as otp;
import 'piv_test.dart' as piv;

const testApps = String.fromEnvironment('TEST_APPS');

const tests = {
  'oath': oath.main,
  'fido': fido.main,
  'piv': piv.main,
  'otp': otp.main,
};

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
