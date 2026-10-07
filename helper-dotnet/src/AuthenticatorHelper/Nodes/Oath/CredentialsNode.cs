using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Oath;

namespace Yubico.Authenticator.Helper.Nodes.Oath;

/// <summary>["ccid", "oath", "accounts"]. Port of CredentialsNode in oath.py.</summary>
internal sealed class CredentialsNode : RpcNode
{
    private readonly OathSession _session;
    private Dictionary<string, Credential> _credentials = new(StringComparer.Ordinal);

    private CredentialsNode(OathSession session)
    {
        _session = session;
        AddAction("calculate_all", CalculateAllAsync);
        AddAction("put", PutAsync);
    }

    public static async ValueTask<RpcNode> CreateAsync(OathSession session, RpcContext context)
    {
        var node = new CredentialsNode(session);
        await node.RefreshAsync(context.CancellationToken).ConfigureAwait(false);
        return node;
    }

    public static JsonObject ToJson(Credential credential) => new()
    {
        ["device_id"] = credential.DeviceId,
        ["id"] = Json.Hex(credential.Id.Span),
        ["issuer"] = credential.Issuer,
        ["name"] = credential.Name,
        ["oath_type"] = (int)credential.OathType,
        ["period"] = credential.Period,
        ["touch_required"] = credential.TouchRequired ?? false,
    };

    public static JsonObject ToJson(Code code) => new()
    {
        ["value"] = code.Value,
        ["valid_from"] = code.ValidFrom,
        ["valid_to"] = code.ValidTo,
    };

    public async ValueTask RefreshAsync(CancellationToken cancellationToken)
    {
        // calculate_all (not list) because it reports whether a TOTP credential requires touch.
        var all = await _session.CalculateAllAsync(null, cancellationToken).ConfigureAwait(false);
        _credentials = all.Keys.ToDictionary(c => Json.Hex(c.Id.Span), StringComparer.Ordinal);
        if (ChildName is { } name && !_credentials.ContainsKey(name))
        {
            await CloseChildAsync().ConfigureAwait(false);
        }
    }

    protected override ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (id, credential) in _credentials)
        {
            result[id] = ToJson(credential);
        }

        return ValueTask.FromResult(result);
    }

    protected override ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context) =>
        _credentials.TryGetValue(name, out var credential)
            ? ValueTask.FromResult<RpcNode>(new CredentialNode(_session, credential, RefreshAsync))
            : throw new NoSuchNodeException(name);

    private async ValueTask<RpcResponse> CalculateAllAsync(JsonObject body, RpcContext context)
    {
        var result = await _session.CalculateAllAsync(body.GetOptionalLong("timestamp"), context.CancellationToken)
            .ConfigureAwait(false);
        var entries = new JsonArray();
        foreach (var (credential, code) in result)
        {
            entries.Add((JsonNode)new JsonObject
            {
                ["credential"] = ToJson(credential),
                ["code"] = code is null ? null : ToJson(code),
            });
        }

        return new RpcResponse(new JsonObject { ["entries"] = entries });
    }

    private async ValueTask<RpcResponse> PutAsync(JsonObject body, RpcContext context)
    {
        var requireTouch = body.GetBool("require_touch");
        using var data = body.GetOptionalString("uri") is { } uri
            ? ParseUri(uri, requireTouch)
            : FromFields(body, requireTouch);

        var id = data.GetId();
        if (_credentials.ContainsKey(Json.Hex(id)))
        {
            throw new InvalidParametersException("Credential already exists");
        }

        try
        {
            await _session.PutCredentialAsync(data, context.CancellationToken).ConfigureAwait(false);
        }
        catch (ApduException e) when (e.SW == SWConstants.InvalidCommandDataParameter)
        {
            throw new InvalidParametersException("Issuer/name too long");
        }

        var credential = new Credential(
            _session.DeviceId, id, data.Issuer, data.Name, data.OathType, data.Period, data.RequireTouch);
        _credentials[Json.Hex(id)] = credential;
        return new RpcResponse(ToJson(credential));
    }

    private static CredentialData ParseUri(string uri, bool requireTouch)
    {
        try
        {
            return CredentialData.ParseUri(uri, requireTouch);
        }
        catch (ArgumentException e)
        {
            throw new InvalidParametersException(e.Message);
        }
    }

    private static CredentialData FromFields(JsonObject body, bool requireTouch)
    {
        var oathType = body.GetString("oath_type").ToUpperInvariant() switch
        {
            "TOTP" => OathType.Totp,
            "HOTP" => OathType.Hotp,
            var other => throw new InvalidParametersException($"unknown oath_type '{other}'"),
        };
        var hash = (body.GetOptionalString("hash") ?? "SHA1").ToUpperInvariant() switch
        {
            "SHA1" => OathHashAlgorithm.Sha1,
            "SHA256" => OathHashAlgorithm.Sha256,
            "SHA512" => OathHashAlgorithm.Sha512,
            var other => throw new InvalidParametersException($"unknown hash '{other}'"),
        };
        return new CredentialData
        {
            Name = body.GetString("name"),
            Issuer = body.GetOptionalString("issuer"),
            OathType = oathType,
            HashAlgorithm = hash,
            Secret = body.GetBytes("secret"),
            Digits = body.GetOptionalInt("digits") ?? 6,
            Period = body.GetOptionalInt("period") ?? 30,
            Counter = body.GetOptionalInt("counter") ?? 0,
            RequireTouch = requireTouch,
        };
    }
}
