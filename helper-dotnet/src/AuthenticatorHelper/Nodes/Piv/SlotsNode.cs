using System.Globalization;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Piv;
using Yubico.YubiKit.Piv.DataObjects;

namespace Yubico.Authenticator.Helper.Nodes.Piv;

/// <summary>["ccid", "piv", "slots"]. Port of SlotsNode in piv.py.</summary>
internal sealed class SlotsNode : RpcNode
{
    private readonly PivSession _session;
    private readonly SortedDictionary<string, (PivSlot Slot, PivSlotMetadata? Metadata, X509Certificate2? Certificate)> _slots =
        new(StringComparer.Ordinal);

    private SlotsNode(PivSession session)
    {
        _session = session;
    }

    public static async ValueTask<RpcNode> CreateAsync(PivSession session, RpcContext context)
    {
        var node = new SlotsNode(session);
        await node.RefreshAsync(context.CancellationToken).ConfigureAwait(false);
        return node;
    }

    public static string SlotId(PivSlot slot) => ((int)slot).ToString("x2", CultureInfo.InvariantCulture);

    public static string SlotName(PivSlot slot) => slot switch
    {
        PivSlot.Authentication => "AUTHENTICATION",
        PivSlot.Signature => "SIGNATURE",
        PivSlot.KeyManagement => "KEY_MANAGEMENT",
        PivSlot.CardAuthentication => "CARD_AUTH",
        _ => slot.ToString().ToUpperInvariant(),
    };

    public async ValueTask RefreshAsync(CancellationToken ct)
    {
        var hasMetadata = _session.FirmwareVersion >= new FirmwareVersion(5, 3, 0);

        // Certificates are not disposed here: an open SlotNode may still reference the previous ones.
        _slots.Clear();
        foreach (var slot in Enum.GetValues<PivSlot>())
        {
            if (slot == PivSlot.Attestation)
            {
                continue;
            }

            PivSlotMetadata? metadata = null;
            if (hasMetadata)
            {
                try
                {
                    metadata = await _session.GetSlotMetadataAsync(slot, ct).ConfigureAwait(false);
                }
                catch (Exception e) when (e is ApduException or FormatException)
                {
                }
            }

            X509Certificate2? certificate = null;
            try
            {
                certificate = await _session.GetCertificateAsync(slot, ct).ConfigureAwait(false);
            }
            catch (Exception e) when (e is ApduException or CryptographicException or FormatException)
            {
                // TODO (same as the Python helper): differentiate between none and malformed.
            }

            _slots[SlotId(slot)] = (slot, metadata, certificate);
        }

        if (ChildName is { } name && !_slots.ContainsKey(name))
        {
            await CloseChildAsync().ConfigureAwait(false);
        }
    }

    protected override ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (id, (slot, metadata, certificate)) in _slots)
        {
            result[id] = new JsonObject
            {
                ["slot"] = (int)slot,
                ["name"] = SlotName(slot),
                ["metadata"] = Certificates.MetadataJson(metadata),
                ["cert_info"] = Certificates.CertInfo(certificate),
                ["public_key_match"] = Certificates.PublicKeyMatch(certificate, metadata),
            };
        }

        return ValueTask.FromResult(result);
    }

    protected override ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context) =>
        _slots.TryGetValue(name, out var entry)
            ? ValueTask.FromResult<RpcNode>(new SlotNode(_session, entry.Slot, entry.Metadata, entry.Certificate, RefreshAsync))
            : throw new NoSuchNodeException(name);
}

/// <summary>["ccid", "piv", "slots", "9a"]. Port of SlotNode in piv.py.</summary>
internal sealed class SlotNode : RpcNode
{
    private const string DateFormat = "yyyy-MM-dd";

    private readonly PivSession _session;
    private readonly PivSlot _slot;
    private readonly Func<CancellationToken, ValueTask> _refresh;
    private readonly PivSlotMetadata? _metadata;
    private X509Certificate2? _certificate;

    public SlotNode(
        PivSession session, PivSlot slot, PivSlotMetadata? metadata, X509Certificate2? certificate,
        Func<CancellationToken, ValueTask> refresh)
    {
        _session = session;
        _slot = slot;
        _metadata = metadata;
        _certificate = certificate;
        _refresh = refresh;
        AddAction("delete", DeleteAsync, condition: () => _certificate is not null || _metadata is not null);
        AddAction("move_key", MoveKeyAsync, condition: () => _metadata is not null);
        AddAction("generate", GenerateAsync);
        AddAction("examine_file", ExamineFileAsync);
        AddAction("import_file", ImportFileAsync);
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(new JsonObject
        {
            ["id"] = SlotsNode.SlotId(_slot),
            ["name"] = SlotsNode.SlotName(_slot),
            ["metadata"] = Certificates.MetadataJson(_metadata),
            ["certificate"] = _certificate is null ? null : Certificates.CertificatePem(_certificate),
        });

    private async ValueTask<RpcResponse> DeleteAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var deleteCert = body.GetBool("delete_cert");
        var deleteKey = body.GetBool("delete_key");
        if (!deleteCert && !deleteKey)
        {
            throw new InvalidParametersException("Missing delete option");
        }

        if (deleteCert)
        {
            await _session.DeleteCertificateAsync(_slot, ct).ConfigureAwait(false);
            await RegenerateChuidAsync(ct).ConfigureAwait(false);
            _certificate = null;
        }

        if (deleteKey)
        {
            await _session.DeleteKeyAsync(_slot, ct).ConfigureAwait(false);
        }

        await _refresh(ct).ConfigureAwait(false);
        return new RpcResponse(new JsonObject());
    }

    private async ValueTask<RpcResponse> MoveKeyAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var destination = (PivSlot)int.Parse(body.GetString("destination"), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
        var includeCertificate = body.GetBool("include_certificate");
        using var certificate = includeCertificate ? await _session.GetCertificateAsync(_slot, ct).ConfigureAwait(false) : null;
        if (body.GetBool("overwrite_key"))
        {
            await _session.DeleteKeyAsync(destination, ct).ConfigureAwait(false);
        }

        await _session.MoveKeyAsync(_slot, destination, ct).ConfigureAwait(false);
        if (certificate is not null)
        {
            await _session.StoreCertificateAsync(destination, certificate, PivCertificateCompression.Automatic, ct).ConfigureAwait(false);
            await _session.DeleteCertificateAsync(_slot, ct).ConfigureAwait(false);
            await RegenerateChuidAsync(ct).ConfigureAwait(false);
            _certificate = null;
        }

        await _refresh(ct).ConfigureAwait(false);
        return new RpcResponse(new JsonObject());
    }

    private async ValueTask<RpcResponse> GenerateAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var algorithm = (PivAlgorithm)body.GetInt("key_type");
        var pinPolicy = (PivPinPolicy)(body.GetOptionalInt("pin_policy") ?? 0);
        var touchPolicy = (PivTouchPolicy)(body.GetOptionalInt("touch_policy") ?? 0);
        var generateType = body.GetOptionalString("generate_type") ?? "certificate";

        var publicKey = await _session.GenerateKeyAsync(
                _slot, algorithm, new PivKeyCreationOptions { PinPolicy = pinPolicy, TouchPolicy = touchPolicy }, ct)
            .ConfigureAwait(false);
        var publicKeyPem = Certificates.PublicKeyPem(publicKey.ExportSubjectPublicKeyInfo());

        if (pinPolicy != PivPinPolicy.Never && body.GetOptionalString("pin") is { } pinText)
        {
            var pin = Encoding.UTF8.GetBytes(pinText);
            try
            {
                await _session.VerifyPinAsync(pin, ct).ConfigureAwait(false);
            }
            finally
            {
                CryptographicOperations.ZeroMemory(pin);
            }
        }

        if (touchPolicy is PivTouchPolicy.Always or PivTouchPolicy.Cached)
        {
            context.Signal("touch");
        }

        string result;
        switch (generateType)
        {
            case "publicKey":
                result = publicKeyPem;
                break;
            case "csr":
                {
                    var (request, generator) = Certificates.CreateRequest(
                        _session, _slot, algorithm, publicKey, body.GetString("subject"));
                    result = Certificates.CsrPem(request.CreateSigningRequest(generator));
                    break;
                }

            case "certificate":
                {
                    var (request, generator) = Certificates.CreateRequest(
                        _session, _slot, algorithm, publicKey, body.GetString("subject"));
                    var now = DateTime.UtcNow;
                    var validFrom = ParseDate(body.GetOptionalString("valid_from")) ?? now;
                    var validTo = ParseDate(body.GetOptionalString("valid_to")) ?? now.AddDays(365);
                    var serial = RandomNumberGenerator.GetBytes(20);
                    serial[0] &= 0x7F;
                    using var certificate = request.Create(request.SubjectName, generator, validFrom, validTo, serial);
                    await _session.StoreCertificateAsync(_slot, certificate, PivCertificateCompression.Automatic, ct)
                        .ConfigureAwait(false);
                    await RegenerateChuidAsync(ct).ConfigureAwait(false);
                    result = Certificates.CertificatePem(certificate);
                    break;
                }

            default:
                throw new InvalidParametersException($"Unsupported GENERATE_TYPE: {generateType}");
        }

        await _refresh(ct).ConfigureAwait(false);
        return new RpcResponse(new JsonObject { ["public_key"] = publicKeyPem, ["result"] = result }, "device_info");
    }

    private ValueTask<RpcResponse> ExamineFileAsync(JsonObject body, RpcContext context)
    {
        var data = body.GetBytes("data");
        var password = body.GetOptionalString("password");
        var parsed = ParsedFile.TryParse(data, password);
        if (parsed is null)
        {
            return ValueTask.FromResult(new RpcResponse(new JsonObject { ["status"] = false }));
        }

        using (parsed)
        {
            var response = new JsonObject
            {
                ["status"] = true,
                ["password"] = password is not null,
                ["key_type"] = parsed.KeyType is { } kt ? (int)kt : null,
                ["cert_info"] = Certificates.CertInfo(parsed.Certificate),
            };
            if (_metadata is not null && parsed.Certificate is not null && parsed.PrivateKey is null)
            {
                response["public_key_match"] = Certificates.PublicKeyMatch(parsed.Certificate, _metadata);
            }

            return ValueTask.FromResult(new RpcResponse(response));
        }
    }

    private async ValueTask<RpcResponse> ImportFileAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        using var parsed = ParsedFile.TryParse(body.GetBytes("data"), body.GetOptionalString("password"))
            ?? throw new InvalidParametersException("Wrong/Missing password");
        if (parsed.Certificate is null && parsed.PrivateKey is null)
        {
            throw new InvalidParametersException("Failed to parse");
        }

        PivSlotMetadata? metadata = null;
        string? publicKeyPem = null;
        if (parsed.PrivateKey is { } privateKey)
        {
            var options = new PivKeyCreationOptions
            {
                PinPolicy = (PivPinPolicy)(body.GetOptionalInt("pin_policy") ?? 0),
                TouchPolicy = (PivTouchPolicy)(body.GetOptionalInt("touch_policy") ?? 0),
            };
            await _session.ImportKeyAsync(_slot, privateKey, options, ct).ConfigureAwait(false);
            publicKeyPem = Certificates.PublicKeyPem(parsed.PublicKeySpki!);
            if (_session.FirmwareVersion >= new FirmwareVersion(5, 3, 0))
            {
                metadata = await _session.GetSlotMetadataAsync(_slot, ct).ConfigureAwait(false);
            }
        }

        if (parsed.Certificate is { } certificate)
        {
            await _session.StoreCertificateAsync(_slot, certificate, PivCertificateCompression.Automatic, ct).ConfigureAwait(false);
            await RegenerateChuidAsync(ct).ConfigureAwait(false);
        }

        await _refresh(ct).ConfigureAwait(false);
        return new RpcResponse(new JsonObject
        {
            ["metadata"] = Certificates.MetadataJson(metadata),
            ["public_key"] = publicKeyPem,
            ["certificate"] = parsed.Certificate is null ? null : Certificates.CertificatePem(parsed.Certificate),
        }, "device_info");
    }

    private static DateTime? ParseDate(string? value) =>
        value is null
            ? null
            : DateTime.ParseExact(value, DateFormat, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal);

    private Task RegenerateChuidAsync(CancellationToken ct) =>
        _session.SetCardholderUniqueIdAsync(PivCardholderUniqueId.CreateWithRandomGuid(), ct);
}
