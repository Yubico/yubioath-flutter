using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Fido2;
using Yubico.YubiKit.Fido2.Credentials;
using Yubico.YubiKit.Fido2.Pin;
using CredMan = Yubico.YubiKit.Fido2.CredentialManagement.CredentialManagement;

namespace Yubico.Authenticator.Helper.Nodes.Fido;

/// <summary>["fido", "ctap2", "credentials"]: relying parties. Port of CredentialsRpsNode in fido.py.</summary>
internal sealed class CredentialsRpsNode : RpcNode
{
    private readonly CredMan _credman;
    private Dictionary<string, (string RpId, byte[] RpIdHash)> _rps = new(StringComparer.Ordinal);

    private CredentialsRpsNode(CredMan credman)
    {
        _credman = credman;
    }

    public static async ValueTask<RpcNode> CreateAsync(
        FidoSession session, IPinUvAuthProtocol protocol, byte[] token, RpcContext context)
    {
        var node = new CredentialsRpsNode(new CredMan(session, protocol, token));
        await node.RefreshAsync(context.CancellationToken).ConfigureAwait(false);
        return node;
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        _credman.Dispose();
    }

    public async ValueTask RefreshAsync(CancellationToken cancellationToken)
    {
        var metadata = await _credman.GetCredentialsMetadataAsync(cancellationToken).ConfigureAwait(false);
        _rps = new Dictionary<string, (string, byte[])>(StringComparer.Ordinal);
        if (metadata.ExistingResidentCredentialsCount == 0)
        {
            return;
        }

        var result = await _credman.EnumerateRelyingPartiesAsync(cancellationToken).ConfigureAwait(false);
        foreach (var rp in result.RelyingParties)
        {
            _rps[rp.RelyingParty.Id] = (rp.RelyingParty.Id, rp.RpIdHash.ToArray());
        }
    }

    protected override ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (id, rp) in _rps)
        {
            result[id] = new JsonObject { ["rp_id"] = rp.RpId, ["rp_id_hash"] = Json.Hex(rp.RpIdHash) };
        }

        return ValueTask.FromResult(result);
    }

    protected override async ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context) =>
        _rps.TryGetValue(name, out var rp)
            ? await CredentialsRpNode.CreateAsync(_credman, rp.RpIdHash, RefreshAsync, context).ConfigureAwait(false)
            : throw new NoSuchNodeException(name);
}

/// <summary>["fido", "ctap2", "credentials", rpId]: credentials of one RP. Port of CredentialsRpNode.</summary>
internal sealed class CredentialsRpNode : RpcNode
{
    private readonly CredMan _credman;
    private readonly byte[] _rpIdHash;
    private readonly Func<CancellationToken, ValueTask> _refreshRps;
    private Dictionary<string, JsonObject> _credentials = new(StringComparer.Ordinal);

    private CredentialsRpNode(CredMan credman, byte[] rpIdHash, Func<CancellationToken, ValueTask> refreshRps)
    {
        _credman = credman;
        _rpIdHash = rpIdHash;
        _refreshRps = refreshRps;
    }

    public static async ValueTask<RpcNode> CreateAsync(
        CredMan credman, byte[] rpIdHash, Func<CancellationToken, ValueTask> refreshRps, RpcContext context)
    {
        var node = new CredentialsRpNode(credman, rpIdHash, refreshRps);
        await node.RefreshAsync(context.CancellationToken).ConfigureAwait(false);
        return node;
    }

    protected override ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (id, data) in _credentials)
        {
            result[id] = data.DeepClone();
        }

        return ValueTask.FromResult(result);
    }

    protected override ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context) =>
        _credentials.TryGetValue(name, out var data)
            ? ValueTask.FromResult<RpcNode>(new FidoCredentialNode(_credman, name, (JsonObject)data.DeepClone(), _refreshRps))
            : throw new NoSuchNodeException(name);

    private async ValueTask RefreshAsync(CancellationToken cancellationToken)
    {
        using var result = await _credman.EnumerateCredentialsAsync(_rpIdHash, cancellationToken).ConfigureAwait(false);
        _credentials = new Dictionary<string, JsonObject>(StringComparer.Ordinal);
        foreach (var credential in result.Credentials)
        {
            var id = Json.Hex(credential.CredentialId.Id.Span);
            _credentials[id] = new JsonObject
            {
                ["credential_id"] = new JsonObject { ["type"] = credential.CredentialId.Type, ["id"] = id },
                ["user_id"] = Json.Hex(credential.User.Id.Span),
                ["user_name"] = credential.User.Name,
                ["display_name"] = credential.User.DisplayName,
            };
        }
    }
}

/// <summary>["fido", "ctap2", "credentials", rpId, credentialId]. Port of CredentialNode in fido.py.</summary>
internal sealed class FidoCredentialNode : RpcNode
{
    private readonly JsonObject _data;

    public FidoCredentialNode(CredMan credman, string credentialIdHex, JsonObject data, Func<CancellationToken, ValueTask> refreshRps)
    {
        _data = data;
        AddAction("delete", async (_, context) =>
        {
            var descriptor = PublicKeyCredentialDescriptor.FromCredentialId(Convert.FromHexString(credentialIdHex));
            await credman.DeleteCredentialAsync(descriptor, context.CancellationToken).ConfigureAwait(false);
            await refreshRps(context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject());
        });
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult((JsonObject)_data.DeepClone());
}
