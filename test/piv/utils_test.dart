import 'package:flutter_test/flutter_test.dart';
import 'package:yubico_authenticator/core/models.dart';
import 'package:yubico_authenticator/piv/models.dart';
import 'package:yubico_authenticator/piv/views/utils.dart';

void main() {
  test('RSA-1024 is only offered on non-FIPS firmware before 6', () {
    for (final version in [const Version(5, 7, 0), const Version(6, 0, 0)]) {
      for (final isFips in [false, true]) {
        final keys = getSupportedKeyTypes(version, isFips);
        expect(keys.contains(KeyType.rsa1024), !isFips && version.major < 6);
        expect(keys, contains(KeyType.rsa2048));
      }
    }
  });

  test('TDES management keys are excluded on firmware 6 and FIPS keys', () {
    for (final version in [const Version(5, 7, 0), const Version(6, 0, 0)]) {
      for (final fipsCapable in [false, true]) {
        final keys = getSupportedManagementKeyTypes(version, fipsCapable);
        expect(
          keys.contains(ManagementKeyType.tdes),
          !fipsCapable && version.major < 6,
        );
        expect(
          keys,
          containsAll([
            ManagementKeyType.aes128,
            ManagementKeyType.aes192,
            ManagementKeyType.aes256,
          ]),
        );
      }
    }
  });

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
