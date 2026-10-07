using System.Formats.Asn1;
using System.Globalization;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Cryptography;
using Yubico.YubiKit.Piv;
using PublicKey = System.Security.Cryptography.X509Certificates.PublicKey;

namespace Yubico.Authenticator.Helper.Nodes.Piv;

/// <summary>
/// Certificate and public-key helpers that the Python helper gets from `cryptography` and
/// ykman.piv (cert_info, PEM encoding, CSR / self-signed generation, RFC 4514 names).
/// </summary>
internal static class Certificates
{
    private static readonly byte[] Ed25519SpkiPrefix = Convert.FromHexString("302a300506032b6570032100");
    private static readonly byte[] X25519SpkiPrefix = Convert.FromHexString("302a300506032b656e032100");

    private static readonly Dictionary<string, string> RdnNames = new(StringComparer.Ordinal)
    {
        ["2.5.4.3"] = "CN", ["2.5.4.6"] = "C", ["2.5.4.7"] = "L", ["2.5.4.8"] = "ST", ["2.5.4.9"] = "STREET",
        ["2.5.4.10"] = "O", ["2.5.4.11"] = "OU", ["0.9.2342.19200300.100.1.25"] = "DC",
        ["0.9.2342.19200300.100.1.1"] = "UID",
    };

    public static string PublicKeyPem(byte[] spki) => PemEncoding.WriteString("PUBLIC KEY", spki) + "\n";

    public static string CertificatePem(X509Certificate2 certificate) => certificate.ExportCertificatePem() + "\n";

    /// <summary>X.509 SubjectPublicKeyInfo for the raw PIV-encoded public key in slot metadata.</summary>
    public static byte[] SpkiFromMetadata(PivSlotMetadata metadata)
    {
        switch (metadata.Algorithm)
        {
            case PivAlgorithm.Rsa1024 or PivAlgorithm.Rsa2048 or PivAlgorithm.Rsa3072 or PivAlgorithm.Rsa4096:
                using (var rsa = metadata.GetRsaPublicKey())
                {
                    return rsa.ExportSubjectPublicKeyInfo();
                }

            case PivAlgorithm.EccP256 or PivAlgorithm.EccP384:
                using (var ec = metadata.GetECDsaPublicKey())
                {
                    return ec.ExportSubjectPublicKeyInfo();
                }

            default:
                var raw = metadata.PublicKey.Span;
                var point = raw.Length > 2 && raw[0] == 0x86 ? raw[2..] : raw;
                var prefix = metadata.Algorithm == PivAlgorithm.Ed25519 ? Ed25519SpkiPrefix : X25519SpkiPrefix;
                return [.. prefix, .. point];
        }
    }

    public static JsonObject? MetadataJson(PivSlotMetadata? metadata) => metadata is { } m
        ? new JsonObject
        {
            ["key_type"] = (int)m.Algorithm,
            ["pin_policy"] = (int)m.PinPolicy,
            ["touch_policy"] = (int)m.TouchPolicy,
            ["generated"] = m.IsGenerated,
            ["public_key"] = PublicKeyPem(SpkiFromMetadata(m)),
        }
        : null;

    public static JsonObject? CertInfo(X509Certificate2? certificate)
    {
        if (certificate is null)
        {
            return null;
        }

        return new JsonObject
        {
            ["key_type"] = KeyTypeOf(certificate) is { } keyType ? (int)keyType : null,
            ["subject"] = ToRfc4514(certificate.SubjectName),
            ["issuer"] = ToRfc4514(certificate.IssuerName),
            ["serial"] = SerialHex(certificate),
            ["not_valid_before"] = IsoUtc(certificate.NotBefore),
            ["not_valid_after"] = IsoUtc(certificate.NotAfter),
            ["fingerprint"] = Json.Hex(SHA256.HashData(certificate.RawData)),
        };
    }

    public static bool? PublicKeyMatch(X509Certificate2? certificate, PivSlotMetadata? metadata) =>
        certificate is null || metadata is not { } m
            ? null
            : certificate.PublicKey.ExportSubjectPublicKeyInfo().AsSpan().SequenceEqual(SpkiFromMetadata(m));

    public static PivAlgorithm? KeyTypeOf(X509Certificate2 certificate) => KeyTypeOf(certificate.PublicKey);

    public static PivAlgorithm? KeyTypeOf(byte[] spki) =>
        KeyTypeOf(PublicKey.CreateFromSubjectPublicKeyInfo(spki, out _));

    private static PivAlgorithm? KeyTypeOf(PublicKey publicKey)
    {
        switch (publicKey.Oid.Value)
        {
            case "1.2.840.113549.1.1.1":
                using (var rsa = publicKey.GetRSAPublicKey())
                {
                    return rsa?.KeySize switch
                    {
                        1024 => PivAlgorithm.Rsa1024,
                        2048 => PivAlgorithm.Rsa2048,
                        3072 => PivAlgorithm.Rsa3072,
                        4096 => PivAlgorithm.Rsa4096,
                        _ => null,
                    };
                }

            case "1.2.840.10045.2.1":
                using (var ec = publicKey.GetECDsaPublicKey())
                {
                    return ec?.KeySize switch
                    {
                        256 => PivAlgorithm.EccP256,
                        384 => PivAlgorithm.EccP384,
                        _ => null,
                    };
                }

            case "1.3.101.112":
                return PivAlgorithm.Ed25519;
            case "1.3.101.110":
                return PivAlgorithm.X25519;
            default:
                return null;
        }
    }

    /// <summary>Parses an RFC 4514 string (most specific RDN first), e.g. "CN=Alice,O=Example".</summary>
    public static X500DistinguishedName ParseRfc4514(string name)
    {
        if (string.IsNullOrWhiteSpace(name) || !name.Contains('=', StringComparison.Ordinal))
        {
            throw new CryptographicException("Not a distinguished name");
        }

        return new X500DistinguishedName(name, X500DistinguishedNameFlags.UseCommas | X500DistinguishedNameFlags.Reversed);
    }

    /// <summary>Formats a name like cryptography's Name.rfc4514_string().</summary>
    public static string ToRfc4514(X500DistinguishedName name)
    {
        var parts = new List<string>();
        foreach (var rdn in name.EnumerateRelativeDistinguishedNames(reversed: true))
        {
            if (!rdn.HasMultipleElements)
            {
                parts.Add(FormatAttribute(rdn.GetSingleElementType().Value, rdn.GetSingleElementValue()));
                continue;
            }

            // Multi-valued RDN: SET OF AttributeTypeAndValue, joined with '+'.
            var attributes = new List<string>();
            var set = new AsnReader(rdn.RawData, AsnEncodingRules.DER).ReadSetOf();
            while (set.HasData)
            {
                var attribute = set.ReadSequence();
                var oid = attribute.ReadObjectIdentifier();
                try
                {
                    var value = attribute.ReadCharacterString(attribute.PeekTag() switch
                    {
                        var t when t.HasSameClassAndValue(new Asn1Tag(UniversalTagNumber.PrintableString)) => UniversalTagNumber.PrintableString,
                        var t when t.HasSameClassAndValue(new Asn1Tag(UniversalTagNumber.IA5String)) => UniversalTagNumber.IA5String,
                        var t when t.HasSameClassAndValue(new Asn1Tag(UniversalTagNumber.BMPString)) => UniversalTagNumber.BMPString,
                        var t when t.HasSameClassAndValue(new Asn1Tag(UniversalTagNumber.T61String)) => UniversalTagNumber.T61String,
                        _ => UniversalTagNumber.UTF8String,
                    });
                    attributes.Add(FormatAttribute(oid, value));
                }
                catch (AsnContentException)
                {
                    // Not a string: RFC 4514 hex form of the DER value.
                    attributes.Add($"{ShortName(oid)}=#{Convert.ToHexStringLower(attribute.ReadEncodedValue().Span)}");
                }
            }

            parts.Add(string.Join('+', attributes));
        }

        return string.Join(',', parts);
    }

    private static string FormatAttribute(string? oid, string? value) => $"{ShortName(oid)}={Escape(value ?? string.Empty)}";

    private static string ShortName(string? oid) =>
        oid is not null && RdnNames.TryGetValue(oid, out var shortName) ? shortName : oid ?? string.Empty;

    /// <summary>
    /// Builds a CSR or self-signed certificate whose signature is computed by the key in the PIV slot.
    /// RSA and NIST P-256/P-384 only; .NET's CertificateRequest has no Ed25519 support.
    /// </summary>
    public static (CertificateRequest Request, X509SignatureGenerator Generator) CreateRequest(
        PivSession session, PivSlot slot, PivAlgorithm algorithm, IPublicKey publicKey, string subject)
    {
        var name = ParseRfc4514(subject);
        var spki = publicKey.ExportSubjectPublicKeyInfo();
        var hash = algorithm == PivAlgorithm.EccP384 ? HashAlgorithmName.SHA384 : HashAlgorithmName.SHA256;
        switch (algorithm)
        {
            case PivAlgorithm.Rsa1024 or PivAlgorithm.Rsa2048 or PivAlgorithm.Rsa3072 or PivAlgorithm.Rsa4096:
                var rsa = RSA.Create();
                rsa.ImportSubjectPublicKeyInfo(spki, out _);
                return (new CertificateRequest(name, rsa, hash, RSASignaturePadding.Pkcs1),
                    new PivRsaSignatureGenerator(session, slot, algorithm, rsa));
            case PivAlgorithm.EccP256 or PivAlgorithm.EccP384:
                var ec = ECDsa.Create();
                ec.ImportSubjectPublicKeyInfo(spki, out _);
                return (new CertificateRequest(name, ec, hash),
                    new PivEcdsaSignatureGenerator(session, slot, algorithm, ec));
            default:
                throw new InvalidParametersException($"Certificate generation for {algorithm} is not supported by the prototype");
        }
    }

    public static string CsrPem(byte[] der) => PemEncoding.WriteString("CERTIFICATE REQUEST", der) + "\n";

    private static string Escape(string value)
    {
        var sb = new StringBuilder();
        for (var i = 0; i < value.Length; i++)
        {
            var c = value[i];
            if (c is ',' or '+' or '"' or '\\' or '<' or '>' or ';' || (i == 0 && c is '#' or ' ') || (i == value.Length - 1 && c == ' '))
            {
                sb.Append('\\');
            }

            sb.Append(c);
        }

        return sb.ToString();
    }

    private static string SerialHex(X509Certificate2 certificate)
    {
        var hex = Convert.ToHexStringLower(certificate.SerialNumberBytes.Span).TrimStart('0');
        return hex.Length == 0 ? "0" : hex;
    }

    private static string IsoUtc(DateTime value) =>
        value.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'+00:00'", CultureInfo.InvariantCulture);
}

internal sealed class PivRsaSignatureGenerator(PivSession session, PivSlot slot, PivAlgorithm algorithm, RSA publicKey)
    : X509SignatureGenerator
{
    private readonly X509SignatureGenerator _template = CreateForRSA(publicKey, RSASignaturePadding.Pkcs1);

    public override byte[] GetSignatureAlgorithmIdentifier(HashAlgorithmName hashAlgorithm) =>
        _template.GetSignatureAlgorithmIdentifier(hashAlgorithm);

    public override byte[] SignData(byte[] data, HashAlgorithmName hashAlgorithm)
    {
        var (hash, oid) = hashAlgorithm.Name switch
        {
            "SHA256" => (SHA256.HashData(data), "2.16.840.1.101.3.4.2.1"),
            "SHA384" => (SHA384.HashData(data), "2.16.840.1.101.3.4.2.2"),
            "SHA512" => (SHA512.HashData(data), "2.16.840.1.101.3.4.2.3"),
            _ => throw new CryptographicException($"Unsupported hash {hashAlgorithm}"),
        };

        // EMSA-PKCS1-v1_5: 00 01 FF..FF 00 || DigestInfo. The PIV applet performs raw RSA.
        var writer = new AsnWriter(AsnEncodingRules.DER);
        using (writer.PushSequence())
        {
            using (writer.PushSequence())
            {
                writer.WriteObjectIdentifier(oid);
                writer.WriteNull();
            }

            writer.WriteOctetString(hash);
        }

        var digestInfo = writer.Encode();
        var padded = new byte[publicKey.KeySize / 8];
        padded[1] = 0x01;
        padded.AsSpan(2, padded.Length - digestInfo.Length - 3).Fill(0xFF);
        digestInfo.CopyTo(padded, padded.Length - digestInfo.Length);
        return session.SignOrDecryptAsync(slot, algorithm, padded).GetAwaiter().GetResult().ToArray();
    }

    protected override PublicKey BuildPublicKey() => PublicKey.CreateFromSubjectPublicKeyInfo(
        publicKey.ExportSubjectPublicKeyInfo(), out _);
}

internal sealed class PivEcdsaSignatureGenerator(PivSession session, PivSlot slot, PivAlgorithm algorithm, ECDsa publicKey)
    : X509SignatureGenerator
{
    private readonly X509SignatureGenerator _template = CreateForECDsa(publicKey);

    public override byte[] GetSignatureAlgorithmIdentifier(HashAlgorithmName hashAlgorithm) =>
        _template.GetSignatureAlgorithmIdentifier(hashAlgorithm);

    public override byte[] SignData(byte[] data, HashAlgorithmName hashAlgorithm)
    {
        var hash = hashAlgorithm.Name switch
        {
            "SHA256" => SHA256.HashData(data),
            "SHA384" => SHA384.HashData(data),
            _ => throw new CryptographicException($"Unsupported hash {hashAlgorithm}"),
        };

        // The PIV applet returns a DER-encoded ECDSA-Sig-Value, which is what X.509 expects.
        return session.SignOrDecryptAsync(slot, algorithm, hash).GetAwaiter().GetResult().ToArray();
    }

    protected override PublicKey BuildPublicKey() => PublicKey.CreateFromSubjectPublicKeyInfo(
        publicKey.ExportSubjectPublicKeyInfo(), out _);
}
