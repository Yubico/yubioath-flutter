using System.Diagnostics;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Oath;

namespace Yubico.Authenticator.Helper.Nodes.Oath;

/// <summary>["ccid", "oath", "accounts", "&lt;credential id hex&gt;"]. Port of CredentialNode in oath.py.</summary>
internal sealed class CredentialNode : RpcNode
{
    private readonly OathSession _session;
    private readonly Func<CancellationToken, ValueTask> _refresh;
    private Credential _credential;
    private bool _touch;

    public CredentialNode(OathSession session, Credential credential, Func<CancellationToken, ValueTask> refresh)
    {
        _session = session;
        _credential = credential;
        _refresh = refresh;
        _touch = credential.TouchRequired ?? false;
        AddAction("code", CodeAsync);
        AddAction("calculate", CalculateAsync);
        AddAction("delete", DeleteAsync);
        AddAction("rename", RenameAsync, condition: () => session.FirmwareVersion >= new FirmwareVersion(5, 3, 1));
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(CredentialsNode.ToJson(_credential));

    private async ValueTask<RpcResponse> CodeAsync(JsonObject body, RpcContext context)
    {
        var timestamp = body.GetOptionalLong("timestamp");
        var code = await WithTouchAsync(
            context, () => _session.CalculateCodeAsync(_credential, timestamp, context.CancellationToken)).ConfigureAwait(false);
        return new RpcResponse(CredentialsNode.ToJson(code));
    }

    private async ValueTask<RpcResponse> CalculateAsync(JsonObject body, RpcContext context)
    {
        var challenge = body.GetBytes("challenge");
        var response = await WithTouchAsync(
            context, () => _session.CalculateAsync(_credential, challenge, context.CancellationToken)).ConfigureAwait(false);
        // The SDK returns the raw TAG_RESPONSE value: [digits byte][HMAC]. yubikit's calculate()
        // (and therefore the app's Steam code formatting) expects just the HMAC.
        return new RpcResponse(new JsonObject { ["response"] = Json.Hex(response.Span[1..]) });
    }

    private async ValueTask<RpcResponse> DeleteAsync(JsonObject body, RpcContext context)
    {
        await _session.DeleteCredentialAsync(_credential, context.CancellationToken).ConfigureAwait(false);
        await _refresh(context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject());
    }

    private async ValueTask<RpcResponse> RenameAsync(JsonObject body, RpcContext context)
    {
        try
        {
            _credential = await _session.RenameCredentialAsync(
                    _credential, body.GetOptionalString("issuer"), body.GetString("name"), context.CancellationToken)
                .ConfigureAwait(false);
        }
        catch (ApduException e) when (e.SW == SWConstants.InvalidCommandDataParameter)
        {
            throw new InvalidParametersException("Issuer/name too long");
        }

        await _refresh(context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject { ["credential_id"] = Json.Hex(_credential.Id.Span) });
    }

    /// <summary>
    /// Touch-required credentials get their "touch" signal from <see cref="TouchSignalPrompt"/>. HOTP
    /// credentials do not report touch up front, so (like the Python helper) a timer signals touch
    /// if the calculation has not returned after 0.5 s.
    /// </summary>
    private async Task<T> WithTouchAsync<T>(RpcContext context, Func<Task<T>> action)
    {
        var started = Stopwatch.StartNew();
        using var timer = !_touch && _credential.OathType == OathType.Hotp
            ? new Timer(_ =>
            {
                context.Signal("touch");
                _touch = true;
            }, null, 500, Timeout.Infinite)
            : null;
        try
        {
            return await action().ConfigureAwait(false);
        }
        catch (Exception e) when (e is OathException { Reason: OathFailureReason.Locked }
                                      or ApduException { SW: SWConstants.SecurityStatusNotSatisfied }
                                  && started.Elapsed > TimeSpan.FromSeconds(5))
        {
            throw new Rpc.TimeoutException();
        }
    }
}
