using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using Yubico.YubiKit.Core.Cryptography;
using Yubico.YubiKit.Piv;

namespace Yubico.Authenticator.Helper.Nodes.Piv;

/// <summary>
/// A certificate and/or private key read from a PEM, DER or PKCS#12 file, replacing
/// ykman.util.parse_certificates / parse_private_key. Returns null for a wrong or missing password.
/// </summary>
internal sealed class ParsedFile : IDisposable
{
    private ParsedFile(X509Certificate2? certificate, byte[]? pkcs8)
    {
        Certificate = certificate;
        if (pkcs8 is not null)
        {
            PrivateKey = CreateSdkPrivateKey(pkcs8);
            PublicKeySpki = PublicSpkiFromPkcs8(pkcs8);
            CryptographicOperations.ZeroMemory(pkcs8);
        }
    }

    public X509Certificate2? Certificate { get; }

    public IPrivateKey? PrivateKey { get; }

    public byte[]? PublicKeySpki { get; }

    public PivAlgorithm? KeyType => PublicKeySpki is null
        ? null
        : Certificates.KeyTypeOf(PublicKeySpki);

    public static ParsedFile? TryParse(byte[] data, string? password)
    {
        if (LooksLikePem(data))
        {
            return ParsePem(Encoding.UTF8.GetString(data), password);
        }

        if (TryLoadCertificate(data) is { } der)
        {
            return new ParsedFile(der, null);
        }

        try
        {
            using var key = PrivateKeyFromPkcs8(data);
            return new ParsedFile(null, data);
        }
        catch (CryptographicException)
        {
        }

        try
        {
            // Keep imported private keys out of the OS key store (EphemeralKeySet isn't supported on macOS).
            var flags = X509KeyStorageFlags.Exportable
                | (OperatingSystem.IsMacOS() ? X509KeyStorageFlags.DefaultKeySet : X509KeyStorageFlags.EphemeralKeySet);
            var collection = X509CertificateLoader.LoadPkcs12Collection(data, password, flags);
            var leaf = collection.FirstOrDefault(c => c.HasPrivateKey) ?? collection.FirstOrDefault();
            byte[]? pkcs8 = leaf is null ? null : ExportPkcs8(leaf);
            return new ParsedFile(leaf is null ? null : X509CertificateLoader.LoadCertificate(leaf.RawData), pkcs8);
        }
        catch (CryptographicException)
        {
            // Wrong/missing password, or not a PKCS#12 file at all.
            return null;
        }
    }

    public void Dispose()
    {
        Certificate?.Dispose();
        (PrivateKey as IDisposable)?.Dispose();
    }

    private static IPrivateKey CreateSdkPrivateKey(byte[] pkcs8)
    {
        try
        {
            return RSAPrivateKey.CreateFromPkcs8(pkcs8);
        }
        catch (Exception e) when (e is CryptographicException or ArgumentException or InvalidOperationException)
        {
            return ECPrivateKey.CreateFromPkcs8(pkcs8);
        }
    }

    private static bool LooksLikePem(byte[] data) =>
        Encoding.ASCII.GetString(data, 0, Math.Min(data.Length, 4096)).Contains("-----BEGIN", StringComparison.Ordinal);

    private static ParsedFile? ParsePem(string text, string? password)
    {
        X509Certificate2? certificate = null;
        byte[]? pkcs8 = null;
        var remaining = text.AsSpan();
        while (PemEncoding.TryFind(remaining, out var fields))
        {
            var label = remaining[fields.Label].ToString();
            var der = Convert.FromBase64String(remaining[fields.Base64Data].ToString());
            switch (label)
            {
                case "CERTIFICATE":
                    certificate ??= X509CertificateLoader.LoadCertificate(der);
                    break;
                case "PRIVATE KEY":
                    pkcs8 = der;
                    break;
                case "ENCRYPTED PRIVATE KEY":
                    if (password is null)
                    {
                        return null;
                    }

                    try
                    {
                        pkcs8 = DecryptPkcs8(der, password);
                    }
                    catch (CryptographicException)
                    {
                        return null;
                    }

                    break;
                case "RSA PRIVATE KEY":
                    using (var rsa = RSA.Create())
                    {
                        rsa.ImportRSAPrivateKey(der, out _);
                        pkcs8 = rsa.ExportPkcs8PrivateKey();
                    }

                    break;
                case "EC PRIVATE KEY":
                    using (var ec = ECDsa.Create())
                    {
                        ec.ImportECPrivateKey(der, out _);
                        pkcs8 = ec.ExportPkcs8PrivateKey();
                    }

                    break;
            }

            if (label != "PRIVATE KEY")
            {
                CryptographicOperations.ZeroMemory(der);
            }

            remaining = remaining[fields.Location.End..];
        }

        return new ParsedFile(certificate, pkcs8);
    }

    private static X509Certificate2? TryLoadCertificate(byte[] data)
    {
        try
        {
            return X509CertificateLoader.LoadCertificate(data);
        }
        catch (CryptographicException)
        {
            return null;
        }
    }

    private static AsymmetricAlgorithm PrivateKeyFromPkcs8(byte[] pkcs8)
    {
        try
        {
            var rsa = RSA.Create();
            rsa.ImportPkcs8PrivateKey(pkcs8, out _);
            return rsa;
        }
        catch (CryptographicException)
        {
            var ec = ECDsa.Create();
            ec.ImportPkcs8PrivateKey(pkcs8, out _);
            return ec;
        }
    }

    private static byte[] DecryptPkcs8(byte[] encrypted, string password)
    {
        try
        {
            using var rsa = RSA.Create();
            rsa.ImportEncryptedPkcs8PrivateKey(password, encrypted, out _);
            return rsa.ExportPkcs8PrivateKey();
        }
        catch (CryptographicException)
        {
            using var ec = ECDsa.Create();
            ec.ImportEncryptedPkcs8PrivateKey(password, encrypted, out _);
            return ec.ExportPkcs8PrivateKey();
        }
    }

    private static byte[]? ExportPkcs8(X509Certificate2 certificate)
    {
        using var rsa = certificate.GetRSAPrivateKey();
        if (rsa is not null)
        {
            return rsa.ExportPkcs8PrivateKey();
        }

        using var ec = certificate.GetECDsaPrivateKey();
        return ec?.ExportPkcs8PrivateKey();
    }

    private static byte[]? PublicSpkiFromPkcs8(byte[] pkcs8)
    {
        try
        {
            using var key = PrivateKeyFromPkcs8(pkcs8);
            return key switch
            {
                RSA rsa => rsa.ExportSubjectPublicKeyInfo(),
                ECDsa ec => ec.ExportSubjectPublicKeyInfo(),
                _ => null,
            };
        }
        catch (CryptographicException)
        {
            return null;
        }
    }
}
