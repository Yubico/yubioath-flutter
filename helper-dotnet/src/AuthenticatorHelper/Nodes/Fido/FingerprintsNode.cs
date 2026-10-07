using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Fido2;
using Yubico.YubiKit.Fido2.BioEnrollment;
using Yubico.YubiKit.Fido2.Ctap;
using Yubico.YubiKit.Fido2.Pin;

namespace Yubico.Authenticator.Helper.Nodes.Fido;

/// <summary>
/// ["fido", "ctap2", "fingerprints"]. Port of FingerprintsNode/FingerprintNode in fido.py.
/// Compiled but not hardware-verified (no YubiKey Bio was available).
/// </summary>
internal sealed class FingerprintsNode : RpcNode
{
    private readonly FingerprintBioEnrollment _bio;
    private Dictionary<string, string?> _templates = new(StringComparer.Ordinal);

    private FingerprintsNode(FingerprintBioEnrollment bio)
    {
        _bio = bio;
        AddAction("add", AddAsync);
    }

    public static async ValueTask<RpcNode> CreateAsync(
        FidoSession session, IPinUvAuthProtocol protocol, byte[] token, RpcContext context)
    {
        var node = new FingerprintsNode(new FingerprintBioEnrollment(session, protocol, token));
        await node.RefreshAsync(context.CancellationToken).ConfigureAwait(false);
        return node;
    }

    protected override ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (id, name) in _templates)
        {
            result[id] = new JsonObject { ["name"] = name };
        }

        return ValueTask.FromResult(result);
    }

    protected override ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context) =>
        _templates.TryGetValue(name, out var friendlyName)
            ? ValueTask.FromResult<RpcNode>(new FingerprintNode(_bio, name, friendlyName, RefreshAsync))
            : throw new NoSuchNodeException(name);

    private async ValueTask RefreshAsync(CancellationToken cancellationToken)
    {
        var templates = await _bio.EnumerateEnrollmentsAsync(cancellationToken).ConfigureAwait(false);
        _templates = templates.ToDictionary(
            t => Json.Hex(t.TemplateId.Span),
            t => string.IsNullOrEmpty(t.FriendlyName) ? null : t.FriendlyName,
            StringComparer.Ordinal);
    }

    private async ValueTask<RpcResponse> AddAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var name = body.GetOptionalString("name");
        try
        {
            var sample = await _bio.EnrollBeginAsync(null, ct).ConfigureAwait(false);
            var templateId = sample.TemplateId.ToArray();
            Report(sample, context);
            while (!sample.IsComplete)
            {
                sample = await _bio.EnrollCaptureNextSampleAsync(templateId, null, ct).ConfigureAwait(false);
                Report(sample, context);
            }

            if (name is not null)
            {
                await _bio.SetFriendlyNameAsync(templateId, name, ct).ConfigureAwait(false);
            }

            _templates[Json.Hex(templateId)] = name;
            return new RpcResponse(new JsonObject { ["template_id"] = Json.Hex(templateId), ["name"] = name });
        }
        catch (CtapException e) when (e.Status == CtapStatus.UserActionTimeout)
        {
            throw new InactivityException();
        }
        catch (OperationCanceledException)
        {
            await _bio.EnrollCancelAsync(CancellationToken.None).ConfigureAwait(false);
            throw;
        }
    }

    private static void Report(EnrollmentSampleResult sample, RpcContext context)
    {
        if (sample.LastSampleStatus == FingerprintSampleStatus.Good)
        {
            context.Signal("capture", new JsonObject { ["remaining"] = sample.RemainingSamples });
        }
        else
        {
            context.Signal("capture-error", new JsonObject { ["code"] = (int)sample.LastSampleStatus });
        }
    }
}

internal sealed class FingerprintNode : RpcNode
{
    private readonly string _templateId;
    private string? _name;

    public FingerprintNode(
        FingerprintBioEnrollment bio, string templateId, string? name, Func<CancellationToken, ValueTask> refresh)
    {
        _templateId = templateId;
        _name = name;
        AddAction("rename", async (body, context) =>
        {
            var newName = body.GetString("name");
            await bio.SetFriendlyNameAsync(Convert.FromHexString(templateId), newName, context.CancellationToken)
                .ConfigureAwait(false);
            _name = newName;
            await refresh(context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject());
        });
        AddAction("delete", async (_, context) =>
        {
            await bio.RemoveEnrollmentAsync(Convert.FromHexString(templateId), context.CancellationToken)
                .ConfigureAwait(false);
            await refresh(context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject());
        });
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(new JsonObject { ["template_id"] = _templateId, ["name"] = _name });
}
