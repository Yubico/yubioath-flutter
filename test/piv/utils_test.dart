import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/piv/models.dart';
import 'package:yubico_authenticator/piv/views/utils.dart';

void main() {
  const signingKeys = [KeyType.mlDsa44, KeyType.mlDsa65, KeyType.mlDsa87];
  const kemKeys = [KeyType.mlKem512, KeyType.mlKem768, KeyType.mlKem1024];

  test('post-quantum PIV algorithms require firmware 6', () {
    final older = getSupportedKeyTypes(
      const Version(5, 7, 0),
      false,
      generateType: GenerateType.publicKey,
    );
    final supported = getSupportedKeyTypes(
      const Version(6, 0, 0),
      true,
      generateType: GenerateType.publicKey,
    );

    for (final key in [...signingKeys, ...kemKeys]) {
      expect(older, isNot(contains(key)));
      expect(supported, contains(key));
    }
    expect(signingKeys.map((key) => key.value), [0xe2, 0xe3, 0xe4]);
    expect(kemKeys.map((key) => key.value), [0xe5, 0xe6, 0xe7]);
  });

  test('ML-KEM cannot be selected for a certificate or CSR', () {
    for (final type in [GenerateType.certificate, GenerateType.csr]) {
      final supported = getSupportedKeyTypes(
        const Version(6, 0, 0),
        false,
        generateType: type,
      );
      for (final key in signingKeys) {
        expect(supported, contains(key));
        expect(key.supportsSigning, isTrue);
      }
      for (final key in kemKeys) {
        expect(supported, isNot(contains(key)));
        expect(key.supportsSigning, isFalse);
      }
    }
    expect(KeyType.x25519.supportsSigning, isFalse);
    expect(
      getSupportedKeyTypes(const Version(6, 0, 0), false),
      containsAll(kemKeys),
    );
  });
}
