import Flutter
import CommonCrypto
import CryptoKit
import CoreImage
import UIKit
import XCTest
import YubiKit
@testable import Runner

class RunnerTests: XCTestCase {

  func testQrImageDecodesAccountAndMigrationPayloads() throws {
    let payloads = [
      "otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&issuer=Example",
      "otpauth-migration://offline?data=example",
    ]
    for payload in payloads {
      let filter = try XCTUnwrap(CIFilter(name: "CIQRCodeGenerator"))
      filter.setValue(Data(payload.utf8), forKey: "inputMessage")
      let image = try XCTUnwrap(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 8, y: 8))
      let cgImage = try XCTUnwrap(CIContext().createCGImage(image, from: image.extent))
      let data = try XCTUnwrap(UIImage(cgImage: cgImage).pngData())
      XCTAssertEqual(try QrScanner.decode(data), payload)
    }
    XCTAssertThrowsError(try QrScanner.decode(Data("not an image".utf8)))
    let blank = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 128, height: 128))
    }
    XCTAssertNil(try QrScanner.decode(XCTUnwrap(blank.pngData())))
  }

  func testDistinguishedNamesRoundTripEscapesAndMultipleAttributes() throws {
    let subject = #"CN=Example\, Inc.+UID=alice,O=Yubico,C=SE"#
    let encoded = try PivCrypto.distinguishedName(subject)
    let decoded = try PivCrypto.nameString(encoded)
    XCTAssertEqual(try PivCrypto.distinguishedName(decoded), encoded)
    XCTAssertTrue(decoded.contains(#"CN=Example\, Inc."#))
    XCTAssertThrowsError(try PivCrypto.distinguishedName("CN"))
    XCTAssertThrowsError(try PivCrypto.distinguishedName("CN=trailing\\"))
    XCTAssertThrowsError(try PivCrypto.distinguishedName("NOTANATTRIBUTE=value"))
  }

  func testParsesECPrivateKeysFromPKCS8AndSEC1WithoutLosingPublicKey() throws {
    let key = P256.Signing.PrivateKey()
    let sec1 = PivCrypto.tlv(0x30,
      PivCrypto.integer(Data([1])) +
      PivCrypto.tlv(0x04, key.rawRepresentation) +
      PivCrypto.tlv(0xa0, try PivCrypto.oid("1.2.840.10045.3.1.7")))
    let pkcs8 = PivCrypto.tlv(0x30,
      PivCrypto.integer(Data([0])) +
      PivCrypto.tlv(0x30, try PivCrypto.oid("1.2.840.10045.2.1") + PivCrypto.oid("1.2.840.10045.3.1.7")) +
      PivCrypto.tlv(0x04, sec1))
    for data in [sec1, pkcs8] {
      let material = try PivCrypto.parse(data, password: nil)
      guard case .ec(let parsed) = material.key else { return XCTFail("Expected EC key") }
      XCTAssertEqual(parsed.k, key.rawRepresentation)
      XCTAssertEqual(parsed.publicKey.x963, key.publicKey.x963Representation)
    }
    let pem = PivCrypto.pem("PRIVATE KEY", pkcs8)
    XCTAssertNotNil(try PivCrypto.parse(Data(pem.utf8), password: nil).key)
    XCTAssertThrowsError(try PivCrypto.parse(Data([0x30, 0x03, 0x04]), password: nil))
  }

  func testPBKDF2MatchesKnownVectorAndRejectsUnboundedWork() throws {
    let key = try PivCrypto.deriveKey(password: "password", salt: Data("salt".utf8),
      rounds: 1, length: 20, prf: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1))
    XCTAssertEqual(PivCrypto.hex(key), "0c60c80f961f0e71f3a9b524af6012062fe037a6")
    XCTAssertThrowsError(try PivCrypto.deriveKey(password: "password", salt: Data(),
      rounds: UInt32.max, length: 20, prf: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)))
  }

  func testGeneratedCertificatesAndRequestsHaveValidSignatures() async throws {
    let key = P256.Signing.PrivateKey()
    let publicKey = PublicKey.ec(EC.PublicKey(x963: key.publicKey.x963Representation, curve: .secp256r1)!)
    let subject = try PivCrypto.distinguishedName("CN=Alice,O=Yubico")
    let now = Date()
    for certificate in [true, false] {
      let document = try await PivCrypto.makeDocument(
        key: publicKey, subject: subject,
        validFrom: certificate ? now.addingTimeInterval(-3600) : nil,
        validTo: certificate ? now.addingTimeInterval(3600) : nil
      ) { try key.signature(for: $0).derRepresentation }
      let fields = try PivCrypto.children(document)
      XCTAssertEqual(fields.count, 3)
      let signature = try P256.Signing.ECDSASignature(derRepresentation: fields[2].value.dropFirst())
      XCTAssertTrue(key.publicKey.isValidSignature(signature, for: fields[0].data))
      if certificate {
        let cert = try PivCrypto.validatedCertificate(document)
        XCTAssertEqual(cert.publicKey, publicKey)
        let info = try PivCrypto.certInfo(cert)
        XCTAssertEqual(info["subject"] as? String, "CN=Alice,O=Yubico")
        XCTAssertEqual(info["fingerprint"] as? String, PivCrypto.hex(Data(SHA256.hash(data: document))))
        let parsed = try PivCrypto.parse(Data(PivCrypto.pem("CERTIFICATE", document).utf8), password: nil)
        XCTAssertEqual(try parsed.certificate()?.der, document)
      }
    }
  }

  func testEd25519CertificateMatchesImportedPrivateKey() async throws {
    let key = Curve25519.Signing.PrivateKey()
    let publicKey = PublicKey.ed25519(Ed25519.PublicKey(keyData: key.publicKey.rawRepresentation)!)
    let now = Date()
    let document = try await PivCrypto.makeDocument(
      key: publicKey, subject: PivCrypto.distinguishedName("CN=Ed25519"),
      validFrom: now.addingTimeInterval(-3600), validTo: now.addingTimeInterval(3600)
    ) { try key.signature(for: $0) }
    let cert = try PivCrypto.validatedCertificate(document)
    XCTAssertEqual(try PivCrypto.publicKey(cert), publicKey)
    let pkcs8 = PivCrypto.tlv(0x30,
      PivCrypto.integer(Data([0])) +
      PivCrypto.tlv(0x30, try PivCrypto.oid("1.3.101.112")) +
      PivCrypto.tlv(0x04, PivCrypto.tlv(0x04, key.rawRepresentation)))
    let bundle = PivCrypto.pem("CERTIFICATE", document) + PivCrypto.pem("PRIVATE KEY", pkcs8)
    XCTAssertEqual(try PivCrypto.parse(Data(bundle.utf8), password: nil).certificate()?.der, document)
  }

  func testEncryptedPKCS8RequiresCorrectPassword() throws {
    let key = P256.Signing.PrivateKey()
    let sec1 = PivCrypto.tlv(0x30, PivCrypto.integer(Data([1])) + PivCrypto.tlv(0x04, key.rawRepresentation))
    let plaintext = PivCrypto.tlv(0x30,
      PivCrypto.integer(Data([0])) +
      PivCrypto.tlv(0x30, try PivCrypto.oid("1.2.840.10045.2.1") + PivCrypto.oid("1.2.840.10045.3.1.7")) +
      PivCrypto.tlv(0x04, sec1))
    let salt = Data(repeating: 1, count: 16)
    let iv = Data(repeating: 2, count: 16)
    let encryptionKey = try PivCrypto.deriveKey(password: "test-password", salt: salt, rounds: 128,
      length: 32, prf: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256))
    var encrypted = Data(count: plaintext.count + 16)
    let capacity = encrypted.count
    var written = 0
    let status = encrypted.withUnsafeMutableBytes { output in
      plaintext.withUnsafeBytes { input in
        encryptionKey.withUnsafeBytes { key in
          iv.withUnsafeBytes { iv in
            CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
              key.baseAddress, encryptionKey.count, iv.baseAddress, input.baseAddress, plaintext.count,
              output.baseAddress, capacity, &written)
          }
        }
      }
    }
    XCTAssertEqual(status, CCCryptorStatus(kCCSuccess))
    let kdf = try PivCrypto.tlv(0x30, PivCrypto.oid("1.2.840.113549.1.5.12") +
      PivCrypto.tlv(0x30, PivCrypto.tlv(0x04, salt) + PivCrypto.integer(Data([0x80])) +
        PivCrypto.tlv(0x30, PivCrypto.oid("1.2.840.113549.2.9") + PivCrypto.tlv(0x05, Data()))))
    let cipher = try PivCrypto.tlv(0x30, PivCrypto.oid("2.16.840.1.101.3.4.1.42") + PivCrypto.tlv(0x04, iv))
    let algorithm = try PivCrypto.tlv(0x30, PivCrypto.oid("1.2.840.113549.1.5.13") + PivCrypto.tlv(0x30, kdf + cipher))
    let der = PivCrypto.tlv(0x30, algorithm + PivCrypto.tlv(0x04, encrypted.prefix(written)))
    let material = try PivCrypto.parse(der, password: "test-password")
    XCTAssertTrue(material.encrypted)
    guard case .ec(let parsed) = material.key else { return XCTFail("Expected EC key") }
    XCTAssertEqual(parsed.k, key.rawRepresentation)
    for password in [nil, "incorrect"] {
      XCTAssertThrowsError(try PivCrypto.parse(der, password: password)) { error in
        guard case PivError.invalidPassword = error else { return XCTFail("Expected invalid password, got \(error)") }
      }
    }
  }

}
