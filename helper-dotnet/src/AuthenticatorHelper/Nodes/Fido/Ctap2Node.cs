using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Abstractions;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Fido2;
using Yubico.YubiKit.Fido2.Config;
using Yubico.YubiKit.Fido2.Ctap;
using Yubico.YubiKit.Fido2.Pin;

namespace Yubico.Authenticator.Helper.Nodes.Fido;

/// <summary>
/// ["fido", "ctap2"]. Port of Ctap2Node in helper/helper/fido.py, without persistent PPUAT storage
/// (out of scope), so <c>unlocked_read</c> only reflects the in-memory PIN token.
/// </summary>
internal sealed class Ctap2Node : RpcNode
{
    private const string Name = "fido";

    private readonly ConnectionNode _parent;
    private FidoSession _session;
    private AuthenticatorInfo _info;
    private IPinUvAuthProtocol _protocol;
    private ClientPin _clientPin;
    private byte[]? _token;

    private Ctap2Node(ConnectionNode parent, FidoSession session, AuthenticatorInfo info)
    {
        _parent = parent;
        _session = session;
        _info = info;
        _protocol = CreateProtocol(info);
        _clientPin = new ClientPin(session, _protocol);

        AddAction("reset", ResetAsync);
        AddAction("unlock", UnlockAsync, condition: () => Option("clientPin") == true);
        AddAction("set_pin", SetPinAsync);
        AddAction("enable_ep_attestation", EnableEpAttestationAsync, condition: () => Option("authnrCfg") == true);
        AddChild("credentials", CreateCredentialsAsync,
            () => Option("credMgmt") is not null || Option("credentialMgmtPreview") is not null);
        AddChild("fingerprints", CreateFingerprintsAsync, () => Option("bioEnroll") is not null);
    }

    public static async ValueTask<RpcNode> CreateAsync(ConnectionNode parent, RpcContext context)
    {
        var session = await FidoSession.CreateAsync(parent.Connection, parent.SessionOptions, context.CancellationToken)
            .ConfigureAwait(false);
        var info = await session.GetInfoAsync(context.CancellationToken).ConfigureAwait(false);
        return new Ctap2Node(parent, session, info);
    }

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        try
        {
            return await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
        }
        catch (CtapException e) when (e.Status == CtapStatus.PinAuthInvalid)
        {
            ClearToken();
            throw new AuthRequiredException();
        }
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        ClearToken();
        _clientPin.Dispose();
        await _session.DisposeAsync().ConfigureAwait(false);
    }

    protected override async ValueTask<JsonObject> GetDataAsync(RpcContext context)
    {
        var ct = context.CancellationToken;
        _info = await _session.GetInfoAsync(ct).ConfigureAwait(false);
        var data = new JsonObject
        {
            ["info"] = AuthenticatorInfoJson.ToJson(_info),
            ["unlocked_read"] = _token is not null,
            ["unlocked"] = _token is not null,
        };
        if (Option("clientPin") == true)
        {
            var retries = await _clientPin.GetPinRetriesAsync(ct).ConfigureAwait(false);
            data["pin_retries"] = retries.RetriesRemaining;
            data["power_cycle"] = retries.PowerCycleRequired;
            if (Option("bioEnroll") == true)
            {
                var uv = await _clientPin.GetUvRetriesAsync(ct).ConfigureAwait(false);
                data["uv_retries"] = uv.RetriesRemaining;
            }
        }

        return data;
    }

    private static IPinUvAuthProtocol CreateProtocol(AuthenticatorInfo info) =>
        info.PinUvAuthProtocols.Contains(2) || info.PinUvAuthProtocols.Count == 0
            ? new PinUvAuthProtocolV2()
            : new PinUvAuthProtocolV1();

    private bool? Option(string name) => _info.Options.TryGetValue(name, out var value) ? value : null;

    private async ValueTask<RpcResponse> UnlockAsync(JsonObject body, RpcContext context)
    {
        var permissions = (PinUvAuthTokenPermissions)0;
        if (Option("credMgmt") is not null || Option("credentialMgmtPreview") is not null)
        {
            permissions |= PinUvAuthTokenPermissions.CredentialManagement;
        }

        if (Option("bioEnroll") is not null)
        {
            permissions |= PinUvAuthTokenPermissions.BioEnrollment;
        }

        if (Option("authnrCfg") == true)
        {
            permissions |= PinUvAuthTokenPermissions.AuthenticatorConfig;
        }

        var pin = Encoding.UTF8.GetBytes(body.GetString("pin"));
        try
        {
            ClearToken();
            _token = Option("pinUvAuthToken") == true
                ? await _clientPin.GetPinUvAuthTokenUsingPinAsync(pin, permissions == 0 ? PinUvAuthTokenPermissions.GetAssertion : permissions,
                    permissions == 0 ? "ykman.example.com" : null, context.CancellationToken).ConfigureAwait(false)
                : await _clientPin.GetPinTokenAsync(pin, context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject());
        }
        catch (CtapException e)
        {
            throw await TranslatePinErrorAsync(e, context.CancellationToken).ConfigureAwait(false);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(pin);
        }
    }

    private async ValueTask<RpcResponse> SetPinAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var newPin = Encoding.UTF8.GetBytes(body.GetString("new_pin"));
        var oldPin = body.GetOptionalString("pin") is { } p ? Encoding.UTF8.GetBytes(p) : null;
        try
        {
            var info = await _session.GetInfoAsync(ct).ConfigureAwait(false);
            if (info.Options.TryGetValue("clientPin", out var hasPin) && hasPin)
            {
                await _clientPin.ChangePinAsync(oldPin ?? throw new InvalidParametersException("missing 'pin'"), newPin, ct)
                    .ConfigureAwait(false);
            }
            else
            {
                await _clientPin.SetPinAsync(newPin, ct).ConfigureAwait(false);
            }

            _info = await _session.GetInfoAsync(ct).ConfigureAwait(false);
            return new RpcResponse(new JsonObject(), "device_info");
        }
        catch (CtapException e)
        {
            ClearToken();
            throw await TranslatePinErrorAsync(e, ct).ConfigureAwait(false);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(newPin);
            if (oldPin is not null)
            {
                CryptographicOperations.ZeroMemory(oldPin);
            }
        }
    }

    private async ValueTask<RpcResponse> EnableEpAttestationAsync(JsonObject body, RpcContext context)
    {
        if (Option("clientPin") == true && _token is null)
        {
            throw new AuthRequiredException();
        }

        var config = new AuthenticatorConfig(_session, _protocol, _token ?? []);
        await config.EnableEnterpriseAttestationAsync(context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject());
    }

    /// <summary>
    /// FIDO reset must happen shortly after the key is plugged in, so the app guides the user through
    /// remove -> insert -> touch via "reset" signals. Port of Ctap2Node.reset + ykman's reinsert().
    /// </summary>
    private async ValueTask<RpcResponse> ResetAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var kind = _parent.Connection.GetType();
        ClearToken();
        await _session.DisposeAsync().ConfigureAwait(false);
        await _parent.DisposeConnectionAsync().ConfigureAwait(false);

        // If anything below fails (cancel, timeout, key not reinserted), the parent connection stays
        // disposed and ConnectionNode makes the next command rebuild the subtree.
        var device = await Reinsertion.WaitForReinsertAsync(_parent.Device, context, ct).ConfigureAwait(false);
        await _parent.ReconnectAsync(device, ct).ConfigureAwait(false);
        Log.Debug(Name, $"Reconnected over {kind.Name}, performing reset...");

        _session = await FidoSession.CreateAsync(_parent.Connection, _parent.SessionOptions, ct).ConfigureAwait(false);
        try
        {
            await _session.ResetAsync(ct).ConfigureAwait(false);
        }
        catch (CtapException e) when (e.Status is CtapStatus.UserActionTimeout or CtapStatus.ActionTimeout)
        {
            throw new InactivityException();
        }

        _info = await _session.GetInfoAsync(ct).ConfigureAwait(false);
        _clientPin.Dispose();
        _protocol = CreateProtocol(_info);
        _clientPin = new ClientPin(_session, _protocol);
        return new RpcResponse(new JsonObject(), "device_info", "device_closed");
    }

    private ValueTask<RpcNode> CreateCredentialsAsync(RpcContext context)
    {
        if (_token is null)
        {
            throw new AuthRequiredException();
        }

        return CredentialsRpsNode.CreateAsync(_session, _protocol, _token, context);
    }

    private ValueTask<RpcNode> CreateFingerprintsAsync(RpcContext context)
    {
        if (_token is null)
        {
            throw new AuthRequiredException();
        }

        return FingerprintsNode.CreateAsync(_session, _protocol, _token, context);
    }

    private async Task<Exception> TranslatePinErrorAsync(CtapException e, CancellationToken ct)
    {
        if (e.Status is CtapStatus.PinInvalid or CtapStatus.PinBlocked or CtapStatus.PinAuthBlocked)
        {
            var retries = await _clientPin.GetPinRetriesAsync(ct).ConfigureAwait(false);
            return new PinValidationException(retries.RetriesRemaining, e.Status == CtapStatus.PinAuthBlocked);
        }

        return e.Status == CtapStatus.PinPolicyViolation ? new PinComplexityException() : e;
    }

    private void ClearToken()
    {
        if (_token is not null)
        {
            CryptographicOperations.ZeroMemory(_token);
            _token = null;
        }
    }
}

internal sealed class PinValidationException(int retries, bool authBlocked)
    : RpcException("pin-validation", "Authentication is required",
        new JsonObject { ["retries"] = retries, ["auth_blocked"] = authBlocked });

internal sealed class InactivityException()
    : RpcException("user-action-timeout", "Failed action due to user inactivity.");

/// <summary>
/// Waits for the user to remove and re-insert the key, signalling progress to the app. Reset is
/// destructive, so the reinserted key must be provably the same one: matched by serial, or, for a key
/// without a readable serial, only when it is the sole key attached before and after.
/// </summary>
internal static class Reinsertion
{
    public static async Task<IYubiKey> WaitForReinsertAsync(IYubiKey device, RpcContext context, CancellationToken ct)
    {
        var before = await ScanAsync(ct).ConfigureAwait(false);
        var hasSerial = device.SerialNumber is not null;
        if (!hasSerial && before.Count > 1)
        {
            throw new RpcException("invalid-command", "Remove all other YubiKeys before resetting a key without a serial number");
        }

        context.Signal("reset", new JsonObject { ["state"] = "remove" });
        while (IsPresent(await ScanAsync(ct).ConfigureAwait(false), device, hasSerial))
        {
            await Task.Delay(250, ct).ConfigureAwait(false);
        }

        context.Signal("reset", new JsonObject { ["state"] = "insert" });
        while (true)
        {
            var now = await ScanAsync(ct).ConfigureAwait(false);
            var match = hasSerial
                ? now.FirstOrDefault(d => d.SameDeviceAs(device) == DeviceCorrelation.Same)
                : now.Count == 1 && now[0].AvailableConnections == device.AvailableConnections ? now[0] : null;
            if (match is not null)
            {
                return match;
            }

            await Task.Delay(250, ct).ConfigureAwait(false);
        }
    }

    private static bool IsPresent(IReadOnlyList<IYubiKey> devices, IYubiKey device, bool hasSerial) =>
        hasSerial ? devices.Any(d => d.SameDeviceAs(device) == DeviceCorrelation.Same) : devices.Count > 0;

    private static Task<IReadOnlyList<IYubiKey>> ScanAsync(CancellationToken ct) =>
        YubiKeyManager.FindAllAsync(ConnectionType.All, forceRescan: true, ct);
}
