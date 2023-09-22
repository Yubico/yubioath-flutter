/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/oath/keys.dart' as keys;

import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('PIV Settings', skip: isAndroid, () {
    appTest('Change PIN', (WidgetTester tester) async {});
    appTest('Change PUK', (WidgetTester tester) async {});
    appTest('Change Management Key', (WidgetTester tester) async {});
    appTest('Lock PIN, unlock with PUK', (WidgetTester tester) async {});
    appTest(
        'Lock PUK, unlock with Management Key', (WidgetTester tester) async {});
    appTest('Change Management Key', (WidgetTester tester) async {});
    appTest('Lock Management Key with PIN', (WidgetTester tester) async {});
    appTest('Reset PIV', (WidgetTester tester) async {});
  });

  ///   Distinguished name schema according to RFC 4514
  ///   https://www.ietf.org/rfc/rfc4514.txt
  ///      CN      commonName (2.5.4.3)
  //       L       localityName (2.5.4.7)
  //       ST      stateOrProvinceName (2.5.4.8)
  //       O       organizationName (2.5.4.10)
  //       OU      organizationalUnitName (2.5.4.11)
  //       C       countryName (2.5.4.6)
  //       STREET  streetAddress (2.5.4.9)
  //       DC      domainComponent (0.9.2342.19200300.100.1.25)
  //       UID     userId (0.9.2342.19200300.100.1.1)
  //       Example: CN=cn,L=l,ST=st,O=o,OU=ou,C=c,STREET=street,DC=dc,DC=net,UID=uid

  group('PIV Certificates', skip: isAndroid, () {
    appTest('Generate 9a', (WidgetTester tester) async {
      //  Subject:
      //  RSA1024
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9c', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9d', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
    appTest('Generate 9e', (WidgetTester tester) async {
      //  Subject:
      //  RSA2048
      //  Certificate
      //  Date [unchanged]
    });
  });
}
