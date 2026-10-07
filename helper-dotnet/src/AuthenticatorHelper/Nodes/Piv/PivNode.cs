using System.Diagnostics;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Core.Sessions;
using Yubico.YubiKit.Core.Transports.SmartCard;
using Yubico.YubiKit.Piv;
using PivInvalidPin = Yubico.YubiKit.Piv.InvalidPinException;

namespace Yubico.Authenticator.Helper.Nodes.Piv;

/// <summary>["ccid", "piv"]. Port of PivNode in helper/helper/piv.py.</summary>
internal sealed class PivNode : RpcNode
{
    private readonly PivSession _session;
    private PivPinOnlyMode _pinOnlyMode;

    private PivNode(PivSession session, PivPinOnlyMode pinOnlyMode)
    {
        _session = session;
        _pinOnlyMode = pinOnlyMode;
        AddAction("verify_pin", VerifyPinAsync);
        AddAction("authenticate", AuthenticateAsync);
        AddAction("set_key", SetKeyAsync, condition: () => _session.IsManagementKeyAuthenticated);
        AddAction("change_pin", (b, c) => ChangePinAsync(b, c));
        AddAction("change_puk", (b, c) => PinOperationAsync(b, c, "puk", "new_puk", (s, a, n, ct) => s.ChangePukAsync(a, n, ct)));
        AddAction("unblock_pin", (b, c) => PinOperationAsync(b, c, "puk", "new_pin", (s, a, n, ct) => s.UnblockPinAsync(a, n, ct)));
        AddAction("reset", ResetAsync);
        AddAction("validate_rfc4514", ValidateRfc4514, closesChild: false);
        AddChild("slots", ctx => SlotsNode.CreateAsync(_session, ctx));
    }

    public static async ValueTask<RpcNode> CreateAsync(
        ISmartCardConnection connection, SessionCreationOptions options, RpcContext context)
    {
        var session = await PivSession.CreateAsync(connection, options, context.CancellationToken)
            .ConfigureAwait(false);
        var mode = await ReadPinOnlyModeAsync(session, context.CancellationToken).ConfigureAwait(false);
        return new PivNode(session, mode);
    }

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        try
        {
            return await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
        }
        catch (ApduException e) when (e.SW == SWConstants.SecurityStatusNotSatisfied)
        {
            throw new AuthRequiredException();
        }
        catch (ApduException e)
        {
            throw new ChildResetException($"SW: {e.SW:x4}");
        }
        catch (PivInvalidPin e)
        {
            throw new InvalidPinException(e.RetriesRemaining);
        }
        catch (InvalidOperationException) when (!_session.IsManagementKeyAuthenticated)
        {
            // The SDK refuses management-key operations up front (no typed exception, no SW);
            // the device would have answered 6982, which the app expects as auth-required.
            throw new AuthRequiredException();
        }
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        await _session.DisposeAsync().ConfigureAwait(false);
    }

    protected override async ValueTask<JsonObject> GetDataAsync(RpcContext context)
    {
        var ct = context.CancellationToken;
        JsonObject? metadata = null;
        int pinAttempts;
        if (_session.FirmwareVersion >= new FirmwareVersion(5, 3, 0))
        {
            var pin = await _session.GetPinMetadataAsync(ct).ConfigureAwait(false);
            var puk = await _session.GetPukMetadataAsync(ct).ConfigureAwait(false);
            var mgm = await _session.GetManagementKeyMetadataAsync(ct).ConfigureAwait(false);
            pinAttempts = pin.RetriesRemaining;
            metadata = new JsonObject
            {
                ["pin_metadata"] = PinMetadata(pin.IsDefault, pin.TotalRetries, pin.RetriesRemaining),
                ["puk_metadata"] = PinMetadata(puk.IsDefault, puk.TotalRetries, puk.RetriesRemaining),
                ["management_key_metadata"] = new JsonObject
                {
                    ["key_type"] = (int)mgm.KeyType,
                    ["default_value"] = mgm.IsDefault,
                    ["touch_policy"] = (int)mgm.TouchPolicy,
                },
            };
        }
        else
        {
            pinAttempts = await _session.GetPinAttemptsAsync(ct).ConfigureAwait(false);
        }

        return new JsonObject
        {
            ["version"] = DeviceInfoJson.Version(_session.FirmwareVersion),
            ["authenticated"] = _session.IsManagementKeyAuthenticated,
            ["derived_key"] = _pinOnlyMode.HasFlag(PivPinOnlyMode.PinDerived),
            ["stored_key"] = _pinOnlyMode.HasFlag(PivPinOnlyMode.PinProtected),
            ["supports_bio"] = await SupportsBioAsync(ct).ConfigureAwait(false),
            ["chuid"] = await GetObjectHexAsync(PivDataObject.Chuid, ct).ConfigureAwait(false),
            ["ccc"] = await GetObjectHexAsync(PivDataObject.Capability, ct).ConfigureAwait(false),
            ["pin_attempts"] = pinAttempts,
            ["metadata"] = metadata,
        };
    }

    private static JsonObject PinMetadata(bool isDefault, int total, int remaining) => new()
    {
        ["default_value"] = isDefault,
        ["total_attempts"] = total,
        ["attempts_remaining"] = remaining,
    };

    private static byte[] Utf8(JsonObject body, string key) => Encoding.UTF8.GetBytes(body.GetString(key));

    private static async Task<PivPinOnlyMode> ReadPinOnlyModeAsync(PivSession session, CancellationToken ct)
    {
        try
        {
            return await session.GetPinOnlyModeAsync(ct).ConfigureAwait(false);
        }
        catch (Exception e) when (e is ApduException or FormatException or NotSupportedException)
        {
            Log.Warning("piv", "Couldn't read PIN-only (pivman) mode", e);
            return PivPinOnlyMode.None;
        }
    }

    private async Task<bool> SupportsBioAsync(CancellationToken ct)
    {
        try
        {
            await _session.GetBioMetadataAsync(ct).ConfigureAwait(false);
            return true;
        }
        catch (Exception e) when (e is NotSupportedException or ApduException)
        {
            return false;
        }
    }

    private async Task<JsonNode?> GetObjectHexAsync(int objectId, CancellationToken ct)
    {
        try
        {
            var data = await _session.GetObjectAsync(objectId, ct).ConfigureAwait(false);
            return data.IsEmpty ? null : Json.Hex(data.Span);
        }
        catch (Exception e) when (e is ApduException or FormatException)
        {
            Log.Warning("piv", $"Couldn't read data object {objectId:x}", e);
            return null;
        }
    }

    private async ValueTask<RpcResponse> VerifyPinAsync(JsonObject body, RpcContext context)
    {
        var ct = context.CancellationToken;
        var pin = Utf8(body, "pin");
        try
        {
            await _session.VerifyPinAsync(pin, ct).ConfigureAwait(false);
            if (_pinOnlyMode != PivPinOnlyMode.None)
            {
                // Derived or PIN-protected management key: authenticate with it, then make sure
                // VERIFY PIN is the last thing done (like verify_pin in piv.py).
                _ = await _session.RecoverPinOnlyModeAsync(pin, ct).ConfigureAwait(false);
                await _session.VerifyPinAsync(pin, ct).ConfigureAwait(false);
            }

            return new RpcResponse(new JsonObject { ["status"] = true, ["authenticated"] = _session.IsManagementKeyAuthenticated });
        }
        finally
        {
            CryptographicOperations.ZeroMemory(pin);
        }
    }

    private async ValueTask<RpcResponse> AuthenticateAsync(JsonObject body, RpcContext context)
    {
        var key = body.GetBytes("key");
        var started = Stopwatch.StartNew();
        try
        {
            await _session.AuthenticateAsync(key, context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject { ["status"] = true });
        }
        catch (ApduException e) when (e.SW == SWConstants.SecurityStatusNotSatisfied)
        {
            if (started.Elapsed > TimeSpan.FromSeconds(5))
            {
                throw new Rpc.TimeoutException();
            }

            return new RpcResponse(new JsonObject { ["status"] = false });
        }
        catch (ArgumentException)
        {
            // Wrong key length for the management key type.
            return new RpcResponse(new JsonObject { ["status"] = false });
        }
        finally
        {
            CryptographicOperations.ZeroMemory(key);
        }
    }

    private async ValueTask<RpcResponse> SetKeyAsync(JsonObject body, RpcContext context)
    {
        if (body.GetBool("store_key"))
        {
            throw new InvalidParametersException("store_key (PIN-protected management key) is not supported by the prototype");
        }

        var key = body.GetBytes("key");
        try
        {
            var keyType = (PivManagementKeyType)(body.GetOptionalInt("key_type") ?? (int)PivManagementKeyType.TripleDes);
            await _session.SetManagementKeyAsync(keyType, key, false, context.CancellationToken).ConfigureAwait(false);
            _pinOnlyMode = await ReadPinOnlyModeAsync(_session, context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject(), "device_info");
        }
        finally
        {
            CryptographicOperations.ZeroMemory(key);
        }
    }

    private ValueTask<RpcResponse> ChangePinAsync(JsonObject body, RpcContext context)
    {
        // pivman_change_pin re-derives a PIN-derived management key; the prototype doesn't, so refuse
        // up front rather than leave the management key bound to the old PIN.
        if (_pinOnlyMode.HasFlag(PivPinOnlyMode.PinDerived))
        {
            throw new InvalidParametersException("Changing the PIN of a PIN-derived management key is not supported by the prototype");
        }

        return PinOperationAsync(body, context, "pin", "new_pin", (s, a, n, ct) => s.ChangePinAsync(a, n, ct));
    }

    private async ValueTask<RpcResponse> PinOperationAsync(
        JsonObject body, RpcContext context, string currentKey, string newKey,
        Func<PivSession, byte[], byte[], CancellationToken, Task> operation)
    {
        var current = Utf8(body, currentKey);
        var replacement = Array.Empty<byte>();
        try
        {
            replacement = Utf8(body, newKey);
            await operation(_session, current, replacement, context.CancellationToken).ConfigureAwait(false);
            return new RpcResponse(new JsonObject(), "device_info");
        }
        catch (ApduException e) when (e.SW == SWConstants.ConditionsNotSatisfied)
        {
            throw new PinComplexityException();
        }
        catch (PivInvalidPin e)
        {
            throw new InvalidPinException(e.RetriesRemaining);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(current);
            CryptographicOperations.ZeroMemory(replacement);
        }
    }

    private async ValueTask<RpcResponse> ResetAsync(JsonObject body, RpcContext context)
    {
        await _session.ResetAsync(context.CancellationToken).ConfigureAwait(false);
        _pinOnlyMode = await ReadPinOnlyModeAsync(_session, context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject(), "device_info");
    }

    private static ValueTask<RpcResponse> ValidateRfc4514(JsonObject body, RpcContext context)
    {
        bool valid;
        try
        {
            _ = Certificates.ParseRfc4514(body.GetString("data"));
            valid = true;
        }
        catch (CryptographicException)
        {
            valid = false;
        }

        return ValueTask.FromResult(new RpcResponse(new JsonObject { ["status"] = valid }));
    }
}

internal sealed class InvalidPinException(int attemptsRemaining)
    : RpcException("invalid-pin", "Wrong PIN", new JsonObject { ["attempts_remaining"] = attemptsRemaining });
