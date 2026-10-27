/*
 * Copyright (C) 2026 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 */

import CommonCrypto
import CryptoKit
import CryptoTokenKit
import Foundation
import Security
import YubiKit

enum PivError: LocalizedError {
    case message(String)
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .message(let message): message
        case .invalidPassword: "The file password is missing or incorrect"
        }
    }
}

enum PivCrypto {
    enum PrivateKey {
        case rsa(RSA.PrivateKey)
        case ec(EC.PrivateKey)
        case ed25519(Ed25519.PrivateKey)
        case x25519(X25519.PrivateKey)

        var publicKey: PublicKey {
            switch self {
            case .rsa(let key): .rsa(key.publicKey)
            case .ec(let key): .ec(key.publicKey)
            case .ed25519(let key): .ed25519(key.publicKey)
            case .x25519(let key): .x25519(key.publicKey)
            }
        }
    }

    struct Material {
        var certificates: [X509Cert] = []
        var key: PrivateKey?
        var encrypted = false

        func certificate() throws -> X509Cert? {
            if let key {
                let matching = try certificates.first(where: { try PivCrypto.publicKey($0) == key.publicKey })
                guard certificates.isEmpty || matching != nil else {
                    throw PivError.message("The certificate does not match the private key")
                }
                return matching
            }
            if certificates.count <= 1 { return certificates.first }
            let issuers = try certificates.map { try certificateFields($0).issuer }
            let leaves = try certificates.filter { !issuers.contains(try certificateFields($0).subject) }
            guard leaves.count == 1 else {
                throw PivError.message("Select a file containing exactly one leaf certificate")
            }
            return leaves[0]
        }
    }

    static func tlv(_ tag: TKTLVTag, _ value: Data) -> Data {
        TKBERTLVRecord(tag: tag, value: value).data
    }

    static func records(_ data: Data) throws -> [TKTLVRecord] {
        guard let records = TKBERTLVRecord.sequenceOfRecords(from: data),
              records.reduce(0, { $0 + $1.data.count }) == data.count else {
            throw PivError.message("Invalid ASN.1 data")
        }
        return records
    }

    static func children(_ data: Data, tag: TKTLVTag = 0x30) throws -> [TKTLVRecord] {
        let outer = try records(data)
        guard outer.count == 1, outer[0].tag == tag else {
            throw PivError.message("Unexpected ASN.1 structure")
        }
        return try records(outer[0].value)
    }

    static func pem(_ label: String, _ data: Data) -> String {
        let text = Array(data.base64EncodedString())
        let lines = stride(from: 0, to: text.count, by: 64).map {
            String(text[$0..<min($0 + 64, text.count)])
        }
        return "-----BEGIN \(label)-----\n" + lines.joined(separator: "\n") + "\n-----END \(label)-----\n"
    }

    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    static func unhex(_ text: String) throws -> Data {
        guard text.count.isMultiple(of: 2), text.allSatisfy(\.isHexDigit) else {
            throw PivError.message("Invalid hexadecimal data")
        }
        var bytes = Data()
        var index = text.startIndex
        while index != text.endIndex {
            let end = text.index(index, offsetBy: 2)
            guard let byte = UInt8(text[index..<end], radix: 16) else {
                throw PivError.message("Invalid hexadecimal data")
            }
            bytes.append(byte)
            index = end
        }
        return bytes
    }

    static func integer(_ value: Data) -> Data {
        var bytes = Data(value.drop(while: { $0 == 0 }))
        if bytes.isEmpty { bytes = Data([0]) }
        if bytes.first! & 0x80 != 0 { bytes.insert(0, at: 0) }
        return tlv(0x02, bytes)
    }

    static func oid(_ string: String) throws -> Data {
        let parts = string.split(separator: ".").compactMap { UInt64($0) }
        guard parts.count >= 2, parts.count == string.split(separator: ".").count,
              parts[0] <= 2, parts[0] == 2 || parts[1] < 40,
              parts[1] <= UInt64.max - 80 else {
            throw PivError.message("Invalid object identifier")
        }
        var result = Data()
        for component in [parts[0] * 40 + parts[1]] + parts.dropFirst(2) {
            var value = component
            var bytes = [UInt8(value & 0x7f)]
            value >>= 7
            while value > 0 {
                bytes.insert(UInt8(value & 0x7f) | 0x80, at: 0)
                value >>= 7
            }
            result.append(contentsOf: bytes)
        }
        return tlv(0x06, result)
    }

    static func oidString(_ data: Data) throws -> String {
        var components: [UInt64] = []
        var value: UInt64 = 0
        for byte in data {
            guard value <= UInt64.max >> 7 else { throw PivError.message("Invalid object identifier") }
            value = (value << 7) | UInt64(byte & 0x7f)
            if byte & 0x80 == 0 { components.append(value); value = 0 }
        }
        guard let first = components.first, data.last.map({ $0 & 0x80 == 0 }) == true else {
            throw PivError.message("Invalid object identifier")
        }
        return ([min(first / 40, 2), first - min(first / 40, 2) * 40] + components.dropFirst())
            .map(String.init).joined(separator: ".")
    }

    private static let names = [
        "CN": "2.5.4.3", "C": "2.5.4.6", "L": "2.5.4.7", "ST": "2.5.4.8",
        "O": "2.5.4.10", "OU": "2.5.4.11", "STREET": "2.5.4.9", "SERIALNUMBER": "2.5.4.5",
        "DC": "0.9.2342.19200300.100.1.25", "UID": "0.9.2342.19200300.100.1.1",
        "EMAILADDRESS": "1.2.840.113549.1.9.1",
    ]

    private static func splitDn(_ text: String, separator: Character) throws -> [String] {
        var escaped = false
        var parts = [""]
        for character in text {
            if !escaped && character == separator {
                parts.append("")
            } else {
                parts[parts.count - 1].append(character)
            }
            if character == "\\" && !escaped { escaped = true } else { escaped = false }
        }
        guard !escaped else { throw PivError.message("Incomplete distinguished-name escape") }
        return parts
    }

    static func distinguishedName(_ text: String) throws -> Data {
        guard !text.isEmpty else { throw PivError.message("Certificate subject must not be empty") }
        var rdns: [Data] = []
        for rdn in try splitDn(text, separator: ",") {
            var attributes: [Data] = []
            for attribute in try splitDn(rdn, separator: "+") {
                guard let equal = attribute.firstIndex(of: "=") else {
                    throw PivError.message("Expected attribute=value in certificate subject")
                }
                let name = attribute[..<equal].trimmingCharacters(in: .whitespaces)
                let type = try oid(names[name.uppercased()] ?? name)
                let raw = String(attribute[attribute.index(after: equal)...])
                let encoded: Data
                if raw.hasPrefix("#") {
                    encoded = try unhex(String(raw.dropFirst()))
                    guard try records(encoded).count == 1 else { throw PivError.message("Invalid subject attribute") }
                } else {
                    var bytes = Data()
                    let chars = Array(raw.utf8)
                    var index = 0
                    while index < chars.count {
                        if chars[index] == 92 {
                            index += 1
                            guard index < chars.count else { throw PivError.message("Incomplete subject escape") }
                            if index + 1 < chars.count,
                               let byte = UInt8(String(bytes: chars[index...index + 1], encoding: .utf8) ?? "", radix: 16) {
                                bytes.append(byte)
                                index += 2
                                continue
                            }
                        }
                        bytes.append(chars[index])
                        index += 1
                    }
                    guard !bytes.isEmpty, String(data: bytes, encoding: .utf8) != nil else {
                        throw PivError.message("Invalid certificate subject value")
                    }
                    let tag: TKTLVTag = name.uppercased() == "C" ? 0x13 :
                        (["DC", "EMAILADDRESS"].contains(name.uppercased()) ? 0x16 : 0x0c)
                    encoded = tlv(tag, bytes)
                }
                attributes.append(tlv(0x30, type + encoded))
            }
            attributes.sort { $0.lexicographicallyPrecedes($1) }
            rdns.append(tlv(0x31, attributes.reduce(Data(), +)))
        }
        return tlv(0x30, rdns.reversed().reduce(Data(), +))
    }

    static func nameString(_ data: Data) throws -> String {
        try children(data).reversed().map { rdn in
            try records(rdn.value).map { attribute in
                let pair = try records(attribute.value)
                guard pair.count == 2, pair[0].tag == 0x06 else { throw PivError.message("Invalid certificate name") }
                let id = try oidString(pair[0].value)
                let label = names.first(where: { $0.value == id })?.key ?? id
                let value: String
                if [0x0c, 0x13, 0x16, 0x14].contains(pair[1].tag),
                   let text = String(data: pair[1].value, encoding: .utf8) {
                    value = text.enumerated().map { offset, char in
                        let escape = ",+\"\\<>;=".contains(char) ||
                            (offset == 0 && (char == " " || char == "#")) ||
                            (offset == text.count - 1 && char == " ")
                        return (escape ? "\\" : "") + String(char)
                    }.joined()
                } else {
                    value = "#" + hex(pair[1].data)
                }
                return "\(label)=\(value)"
            }.joined(separator: "+")
        }.joined(separator: ",")
    }

    struct CertificateFields {
        let subject: Data
        let issuer: Data
        let serial: Data
        let validity: [TKTLVRecord]
        let publicKeyData: Data
    }

    static func certificateFields(_ cert: X509Cert) throws -> CertificateFields {
        let outer = try children(cert.der)
        guard outer.count == 3 else { throw PivError.message("Invalid X.509 certificate") }
        let tbs = try records(outer[0].value)
        let start = tbs.first?.tag == 0xa0 ? 1 : 0
        guard tbs.count >= start + 6 else { throw PivError.message("Incomplete X.509 certificate") }
        let validity = try records(tbs[start + 3].value)
        guard validity.count == 2 else { throw PivError.message("Invalid certificate validity") }
        return CertificateFields(subject: tbs[start + 4].data, issuer: tbs[start + 2].data,
                                 serial: tbs[start].value, validity: validity, publicKeyData: tbs[start + 5].data)
    }

    static func publicKey(_ cert: X509Cert) throws -> PublicKey? {
        if let key = cert.publicKey { return key }
        let fields = try children(certificateFields(cert).publicKeyData)
        guard fields.count == 2, fields[1].tag == 0x03, fields[1].value.first == 0 else {
            throw PivError.message("Invalid certificate public key")
        }
        let algorithm = try records(fields[0].value)
        guard let id = algorithm.first, id.tag == 0x06 else { throw PivError.message("Missing certificate key algorithm") }
        let raw = Data(fields[1].value.dropFirst())
        switch try oidString(id.value) {
        case "1.3.101.112": return Ed25519.PublicKey(keyData: raw).map(PublicKey.ed25519)
        case "1.3.101.110": return X25519.PublicKey(keyData: raw).map(PublicKey.x25519)
        default: return nil
        }
    }

    static func parseTime(_ record: TKTLVRecord) throws -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = record.tag == 0x17 ? "yyMMddHHmmss'Z'" : "yyyyMMddHHmmss'Z'"
        formatter.twoDigitStartDate = Date(timeIntervalSince1970: -631152000)
        guard [0x17, 0x18].contains(record.tag),
              let string = String(data: record.value, encoding: .ascii),
              let date = formatter.date(from: string) else { throw PivError.message("Invalid certificate date") }
        return date
    }

    static func dateString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func certInfo(_ cert: X509Cert) throws -> [String: Any] {
        let fields = try certificateFields(cert)
        return [
            "key_type": try publicKey(cert).map { keyType($0).rawValue as Any } ?? NSNull(),
            "subject": try nameString(fields.subject), "issuer": try nameString(fields.issuer),
            "serial": decimal(fields.serial),
            "not_valid_before": dateString(try parseTime(fields.validity[0])),
            "not_valid_after": dateString(try parseTime(fields.validity[1])),
            "fingerprint": hex(Data(SHA256.hash(data: cert.der))),
        ]
    }

    static func keyType(_ key: PublicKey) -> PIV.KeyType {
        switch key {
        case .rsa(let key): .rsa(key.size)
        case .ec(let key): .ec(key.curve)
        case .ed25519: .ed25519
        case .x25519: .x25519
        }
    }

    private static func decimal(_ data: Data) -> String {
        var digits = [0]
        for byte in data {
            var carry = Int(byte)
            for index in digits.indices {
                carry += digits[index] * 256
                digits[index] = carry % 10
                carry /= 10
            }
            while carry > 0 { digits.append(carry % 10); carry /= 10 }
        }
        return digits.reversed().map(String.init).joined()
    }

    static func generateDocument(
        session: PIVSession, slot: PIV.Slot, key: PublicKey, subject: Data,
        validFrom: Date?, validTo: Date?
    ) async throws -> Data {
        try await makeDocument(key: key, subject: subject, validFrom: validFrom, validTo: validTo) { body in
            switch key {
            case .rsa(let key):
                return try await session.sign(body, in: slot, keyType: .rsa(key.size), using: .pkcs1v15(.sha256))
            case .ec(let key):
                return try await session.sign(body, in: slot, keyType: .ec(key.curve), using: .hash(.sha256))
            case .ed25519:
                return try await session.sign(body, in: slot, keyType: .ed25519)
            case .x25519: throw PivError.message("X25519 keys cannot sign")
            }
        }
    }

    static func makeDocument(
        key: PublicKey, subject: Data, validFrom: Date?, validTo: Date?,
        sign: (Data) async throws -> Data
    ) async throws -> Data {
        let algorithm: Data
        switch key {
        case .rsa: algorithm = try tlv(0x30, oid("1.2.840.113549.1.1.11") + tlv(0x05, Data()))
        case .ec: algorithm = try tlv(0x30, oid("1.2.840.10045.4.3.2"))
        case .ed25519: algorithm = try tlv(0x30, oid("1.3.101.112"))
        case .x25519: throw PivError.message("X25519 keys cannot sign certificates or certificate requests")
        }
        let body: Data
        if let validFrom, let validTo {
            guard validTo > validFrom else { throw PivError.message("Certificate expiry must follow its start date") }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyyMMddHHmmss'Z'"
            let validity = tlv(0x30, tlv(0x18, Data(formatter.string(from: validFrom).utf8)) +
                               tlv(0x18, Data(formatter.string(from: validTo).utf8)))
            var serial = Data(count: 20)
            let status = serial.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 20, $0.baseAddress!) }
            guard status == errSecSuccess else { throw PivError.message("Could not generate certificate serial") }
            serial[0] &= 0x7f
            body = tlv(0x30, tlv(0xa0, integer(Data([2]))) + integer(serial) + algorithm +
                       subject + validity + subject + key.spki)
        } else {
            body = tlv(0x30, integer(Data([0])) + subject + key.spki + tlv(0xa0, Data()))
        }
        let signature = try await sign(body)
        return tlv(0x30, body + algorithm + tlv(0x03, Data([0]) + signature))
    }

    static func parse(_ data: Data, password: String?) throws -> Material {
        if let text = String(data: data, encoding: .utf8), text.contains("-----BEGIN ") {
            let regex = try NSRegularExpression(pattern: "-----BEGIN ([A-Z0-9 ]+)-----([\\s\\S]*?)-----END \\1-----")
            var material = Material()
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                let label = String(text[Range(match.range(at: 1), in: text)!])
                let body = String(text[Range(match.range(at: 2), in: text)!])
                let legacyEncrypted = body.contains("Proc-Type:")
                let der: Data
                if legacyEncrypted {
                    der = try decryptPEM(body, password: password)
                } else {
                    guard let decoded = Data(base64Encoded: body, options: .ignoreUnknownCharacters) else {
                        throw PivError.message("Invalid PEM encoding")
                    }
                    der = decoded
                }
                if label == "CERTIFICATE" {
                    material.certificates.append(try validatedCertificate(der))
                } else if ["PRIVATE KEY", "RSA PRIVATE KEY", "EC PRIVATE KEY", "ENCRYPTED PRIVATE KEY"].contains(label) {
                    guard material.key == nil else { throw PivError.message("Select a file containing only one private key") }
                    material.encrypted = legacyEncrypted || label == "ENCRYPTED PRIVATE KEY"
                    material.key = try privateKey(label == "ENCRYPTED PRIVATE KEY" ? decryptPKCS8(der, password: password) : der)
                } else {
                    throw PivError.message("Unsupported PEM object: \(label)")
                }
            }
            guard material.key != nil || !material.certificates.isEmpty else { throw PivError.message("No certificate or private key found") }
            return material
        }
        if SecCertificateCreateWithData(nil, data as CFData) != nil {
            return Material(certificates: [try validatedCertificate(data)])
        }
        let fields = try children(data)
        if fields.count >= 2, fields[0].tag == 0x30, fields[1].tag == 0x04 {
            return Material(key: try privateKey(decryptPKCS8(data, password: password)), encrypted: true)
        }
        if fields.count >= 2, fields[0].tag == 0x02, fields[1].tag == 0x30,
           let alg = try records(fields[1].value).first, alg.tag == 0x06,
           try oidString(alg.value) == "1.2.840.113549.1.7.1" {
            return try pkcs12(data, password: password)
        }
        return Material(key: try privateKey(data))
    }

    static func validatedCertificate(_ data: Data) throws -> X509Cert {
        guard SecCertificateCreateWithData(nil, data as CFData) != nil else {
            throw PivError.message("Invalid X.509 certificate")
        }
        let cert = X509Cert(der: data)
        _ = try certificateFields(cert)
        return cert
    }

    static func privateKey(_ data: Data) throws -> PrivateKey {
        let fields = try children(data)
        if fields.count == 9, let key = RSA.PrivateKey(pkcs1: data) { return .rsa(key) }
        if fields.count >= 3, fields[1].tag == 0x30, fields[2].tag == 0x04 {
            let alg = try records(fields[1].value)
            guard let first = alg.first, first.tag == 0x06 else { throw PivError.message("Missing private key algorithm") }
            switch try oidString(first.value) {
            case "1.2.840.113549.1.1.1":
                guard let key = RSA.PrivateKey(pkcs1: fields[2].value) else { throw PivError.message("Invalid RSA private key") }
                return .rsa(key)
            case "1.2.840.10045.2.1":
                guard alg.count == 2 else { throw PivError.message("Missing EC curve") }
                return try ecPrivateKey(fields[2].value, curveOid: oidString(alg[1].value))
            case "1.3.101.112", "1.3.101.110":
                let seed = try records(fields[2].value)
                guard seed.count == 1, seed[0].tag == 0x04 else { throw PivError.message("Invalid Curve25519 private key") }
                if try oidString(first.value) == "1.3.101.112", let key = Ed25519.PrivateKey(seed: seed[0].value) {
                    return .ed25519(key)
                }
                if let key = X25519.PrivateKey(scalar: seed[0].value) { return .x25519(key) }
                throw PivError.message("Invalid Curve25519 private key")
            default: throw PivError.message("Unsupported private key algorithm")
            }
        }
        if fields.count >= 2, fields[1].tag == 0x04 {
            guard let params = fields.first(where: { $0.tag == 0xa0 }),
                  let curve = try records(params.value).first else { throw PivError.message("Missing EC curve") }
            return try ecPrivateKey(data, curveOid: oidString(curve.value))
        }
        throw PivError.message("Unsupported private key format")
    }

    private static func ecPrivateKey(_ data: Data, curveOid: String) throws -> PrivateKey {
        let fields = try children(data)
        guard fields.count >= 2, fields[1].tag == 0x04 else { throw PivError.message("Invalid EC private key") }
        let scalar = fields[1].value
        let curve: EC.Curve
        let point: Data
        switch curveOid {
        case "1.2.840.10045.3.1.7":
            curve = .secp256r1
            point = try P256.Signing.PrivateKey(rawRepresentation: scalar).publicKey.x963Representation
        case "1.3.132.0.34":
            curve = .secp384r1
            point = try P384.Signing.PrivateKey(rawRepresentation: scalar).publicKey.x963Representation
        default: throw PivError.message("Only P-256 and P-384 EC keys are supported")
        }
        guard let key = EC.PrivateKey(x963: point + scalar, curve: curve) else { throw PivError.message("Invalid EC private key") }
        return .ec(key)
    }

    private static func pkcs12(_ data: Data, password: String?) throws -> Material {
        var result: CFArray?
        let status = SecPKCS12Import(data as CFData, [kSecImportExportPassphrase as String: password ?? ""] as CFDictionary, &result)
        if status == errSecAuthFailed { throw PivError.invalidPassword }
        guard status == errSecSuccess, let items = result as? [[String: Any]], items.count == 1,
              let identityValue = items[0][kSecImportItemIdentity as String] else {
            throw PivError.message("Could not import PKCS#12 identity (\(status)); select a file with one identity")
        }
        guard CFGetTypeID(identityValue as CFTypeRef) == SecIdentityGetTypeID() else {
            throw PivError.message("Invalid PKCS#12 identity")
        }
        let identity = identityValue as! SecIdentity
        var key: SecKey?
        guard SecIdentityCopyPrivateKey(identity, &key) == errSecSuccess, let key,
              let attributes = SecKeyCopyAttributes(key) as? [String: Any],
              let external = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            throw PivError.message("Could not read PKCS#12 private key")
        }
        let parsed: PrivateKey
        if attributes[kSecAttrKeyType as String] as? String == kSecAttrKeyTypeRSA as String {
            parsed = try privateKey(external)
        } else {
            let curve: EC.Curve = (attributes[kSecAttrKeySizeInBits as String] as? Int) == 384 ? .secp384r1 : .secp256r1
            guard let ec = EC.PrivateKey(x963: external, curve: curve) else { throw PivError.message("Unsupported PKCS#12 key") }
            parsed = .ec(ec)
        }
        let chain = items[0][kSecImportItemCertChain as String] as? [SecCertificate] ?? []
        return Material(certificates: chain.map { X509Cert(der: SecCertificateCopyData($0) as Data) }, key: parsed, encrypted: true)
    }

    static func deriveKey(password: String, salt: Data, rounds: UInt32, length: Int, prf: CCPseudoRandomAlgorithm) throws -> Data {
        guard rounds > 0, rounds <= 10_000_000, length > 0, length <= 64 else {
            throw PivError.message("Unsupported password derivation parameters")
        }
        var key = Data(count: length)
        let status = key.withUnsafeMutableBytes { output in
            salt.withUnsafeBytes { saltBytes in
                password.withCString { text in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), text, password.utf8.count,
                                        saltBytes.bindMemory(to: UInt8.self).baseAddress, salt.count,
                                        prf, rounds, output.bindMemory(to: UInt8.self).baseAddress, length)
                }
            }
        }
        guard status == kCCSuccess else { throw PivError.message("Password derivation failed") }
        return key
    }

    private static func decryptPEM(_ body: String, password: String?) throws -> Data {
        let normalized = body.replacingOccurrences(of: "\r\n", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let sections = normalized.components(separatedBy: "\n\n")
        guard sections.count == 2,
              let dek = sections[0].components(separatedBy: "\n").first(where: { $0.hasPrefix("DEK-Info:") }),
              let encrypted = Data(base64Encoded: sections[1], options: .ignoreUnknownCharacters) else {
            throw PivError.message("Invalid encrypted PEM headers")
        }
        let parameters = dek.dropFirst("DEK-Info:".count).trimmingCharacters(in: .whitespaces).components(separatedBy: ",")
        let ciphers: [String: (Int, CCAlgorithm, Int)] = [
            "AES-128-CBC": (16, CCAlgorithm(kCCAlgorithmAES), 16),
            "AES-192-CBC": (24, CCAlgorithm(kCCAlgorithmAES), 16),
            "AES-256-CBC": (32, CCAlgorithm(kCCAlgorithmAES), 16),
            "DES-EDE3-CBC": (24, CCAlgorithm(kCCAlgorithm3DES), 8),
            "DES-CBC": (8, CCAlgorithm(kCCAlgorithmDES), 8),
        ]
        guard parameters.count == 2, let (length, algorithm, blockSize) = ciphers[parameters[0]] else {
            throw PivError.message("Unsupported encrypted PEM cipher")
        }
        let iv = try unhex(parameters[1])
        guard iv.count == blockSize else { throw PivError.message("Invalid encrypted PEM IV") }
        guard let password else { throw PivError.invalidPassword }
        // Traditional OpenSSL PEM uses EVP_BytesToKey with MD5 and the first
        // eight IV bytes as salt. This is only used to read existing files.
        var key = Data()
        var previous = Data()
        while key.count < length {
            let input = previous + Data(password.utf8) + iv.prefix(8)
            let digest = Data(Insecure.MD5.hash(data: input))
            previous = digest
            key.append(digest)
        }
        defer { key.resetBytes(in: 0..<key.count) }
        return try decryptCBC(encrypted, key: Data(key.prefix(length)), iv: iv, algorithm: algorithm, blockSize: blockSize)
    }

    private static func decryptCBC(_ encrypted: Data, key: Data, iv: Data, algorithm: CCAlgorithm, blockSize: Int) throws -> Data {
        var decrypted = Data(count: encrypted.count + blockSize)
        let capacity = decrypted.count
        var written = 0
        let status = decrypted.withUnsafeMutableBytes { output in
            encrypted.withUnsafeBytes { input in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(CCOperation(kCCDecrypt), algorithm, CCOptions(kCCOptionPKCS7Padding),
                                keyBytes.baseAddress, key.count, ivBytes.baseAddress, input.baseAddress, encrypted.count,
                                output.baseAddress, capacity, &written)
                    }
                }
            }
        }
        guard status == kCCSuccess else { throw PivError.invalidPassword }
        let plaintext = Data(decrypted.prefix(written))
        // CBC padding can also be valid with an incorrect password.
        guard let fields = TKBERTLVRecord.sequenceOfRecords(from: plaintext),
              fields.count == 1, fields[0].tag == 0x30,
              fields[0].data.count == plaintext.count else {
            throw PivError.invalidPassword
        }
        return plaintext
    }

    private static func decryptPKCS8(_ data: Data, password: String?) throws -> Data {
        let outer = try children(data)
        guard outer.count == 2 else { throw PivError.message("Invalid encrypted PKCS#8") }
        let alg = try records(outer[0].value)
        guard alg.count == 2, try oidString(alg[0].value) == "1.2.840.113549.1.5.13" else {
            throw PivError.message("Only PBES2 encrypted PKCS#8 is supported")
        }
        let params = try records(alg[1].value)
        guard params.count == 2 else { throw PivError.message("Invalid PBES2 parameters") }
        let kdf = try records(params[0].value)
        let cipher = try records(params[1].value)
        guard kdf.count == 2, cipher.count == 2,
              try oidString(kdf[0].value) == "1.2.840.113549.1.5.12" else {
            throw PivError.message("Only PBKDF2 password derivation is supported")
        }
        let pbkdf = try records(kdf[1].value)
        guard pbkdf.count >= 2, pbkdf[0].tag == 0x04, pbkdf[1].tag == 0x02, pbkdf[1].value.count <= 4 else {
            throw PivError.message("Invalid PBKDF2 parameters")
        }
        let rounds = pbkdf[1].value.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let lengths = ["2.16.840.1.101.3.4.1.2": 16, "2.16.840.1.101.3.4.1.22": 24, "2.16.840.1.101.3.4.1.42": 32]
        guard let length = lengths[try oidString(cipher[0].value)], cipher[1].value.count == 16 else {
            throw PivError.message("Only AES-CBC encrypted PKCS#8 is supported")
        }
        let prfs: [String: CCPseudoRandomAlgorithm] = [
            "1.2.840.113549.2.7": CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
            "1.2.840.113549.2.9": CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            "1.2.840.113549.2.10": CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA384),
            "1.2.840.113549.2.11": CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
        ]
        let prf: CCPseudoRandomAlgorithm
        if let explicit = pbkdf.dropFirst(2).first(where: { $0.tag == 0x30 }),
           let id = try records(explicit.value).first {
            guard let value = prfs[try oidString(id.value)] else { throw PivError.message("Unsupported PBKDF2 hash") }
            prf = value
        } else {
            prf = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)
        }
        guard let password else { throw PivError.invalidPassword }
        var key = try deriveKey(password: password, salt: pbkdf[0].value, rounds: rounds, length: length, prf: prf)
        defer { key.resetBytes(in: 0..<key.count) }
        return try decryptCBC(outer[1].value, key: key, iv: cipher[1].value, algorithm: CCAlgorithm(kCCAlgorithmAES), blockSize: 16)
    }
}
