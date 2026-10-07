using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Core.Sessions;
using Yubico.YubiKit.Core.Transports.SmartCard;
using Yubico.YubiKit.Oath;

namespace Yubico.Authenticator.Helper.Nodes.Oath;

/// <summary>
/// ["ccid", "oath"]. Port of OathNode in helper/helper/oath.py, without the persistent
/// "remember password" keystore (out of scope): <c>remembered</c> is always false.
/// </summary>
internal sealed class OathNode : RpcNode
{
    private readonly OathSession _session;
    private (byte[] Salt, byte[] Digest)? _keyVerifier;

    private OathNode(OathSession session)
    {
        _session = session;
        AddAction("derive", DeriveAsync);
        AddAction("forget", (_, _) => Ok(new JsonObject()));
        AddAction("validate", ValidateAsync);
        AddAction("set_key", SetKeyAsync);
        AddAction("unset_key", UnsetKeyAsync, condition: () => _session.IsPasswordProtected);
        AddAction("reset", ResetAsync);
        AddChild("accounts", CreateAccountsAsync);
    }

    public static async ValueTask<RpcNode> CreateAsync(
        ISmartCardConnection connection, SessionCreationOptions options, RpcContext context)
    {
        var session = await OathSession.CreateAsync(connection, options, context.CancellationToken)
            .ConfigureAwait(false);
        return new OathNode(session);
    }

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        try
        {
            return await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
        }
        catch (OathException e) when (e.Reason == OathFailureReason.Locked)
        {
            throw new AuthRequiredException();
        }
        catch (ApduException e) when (e.SW == SWConstants.SecurityStatusNotSatisfied)
        {
            throw new AuthRequiredException();
        }
        catch (ApduException e)
        {
            throw new ChildResetException($"SW: {e.SW:x4}");
        }
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        await _session.DisposeAsync().ConfigureAwait(false);
        ClearVerifier();
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(new JsonObject
        {
            ["version"] = DeviceInfoJson.Version(_session.FirmwareVersion),
            ["device_id"] = _session.DeviceId,
            ["has_key"] = _session.IsPasswordProtected,
            ["locked"] = _session.IsLocked,
            ["remembered"] = false,
            ["keystore"] = "unknown",
        });

    private static ValueTask<RpcResponse> Ok(JsonObject body, params string[] flags) =>
        ValueTask.FromResult(new RpcResponse(body, flags));

    private ValueTask<RpcResponse> DeriveAsync(JsonObject body, RpcContext context)
    {
        var key = DeriveFromPassword(body.GetString("password"));
        try
        {
            return Ok(new JsonObject { ["key"] = Json.Hex(key) });
        }
        finally
        {
            CryptographicOperations.ZeroMemory(key);
        }
    }

    private async ValueTask<RpcResponse> ValidateAsync(JsonObject body, RpcContext context)
    {
        var key = GetKey(body);
        try
        {
            bool valid;
            if (_session.IsLocked)
            {
                try
                {
                    await _session.ValidateAsync(key, context.CancellationToken).ConfigureAwait(false);
                    SetVerifier(key);
                    valid = true;
                }
                catch (OathException e) when (e.Reason == OathFailureReason.WrongPassword)
                {
                    valid = false;
                }
            }
            else if (_keyVerifier is var (salt, digest))
            {
                valid = CryptographicOperations.FixedTimeEquals(digest, HMACSHA256.HashData(salt, key));
            }
            else
            {
                valid = false;
            }

            return new RpcResponse(new JsonObject { ["valid"] = valid, ["remembered"] = false });
        }
        finally
        {
            CryptographicOperations.ZeroMemory(key);
        }
    }

    private async ValueTask<RpcResponse> SetKeyAsync(JsonObject body, RpcContext context)
    {
        var key = GetKey(body);
        try
        {
            await _session.SetKeyAsync(key, context.CancellationToken).ConfigureAwait(false);
            SetVerifier(key);
            return new RpcResponse(new JsonObject { ["remembered"] = false }, "device_info");
        }
        finally
        {
            CryptographicOperations.ZeroMemory(key);
        }
    }

    private async ValueTask<RpcResponse> UnsetKeyAsync(JsonObject body, RpcContext context)
    {
        await _session.UnsetKeyAsync(context.CancellationToken).ConfigureAwait(false);
        ClearVerifier();
        return new RpcResponse(new JsonObject());
    }

    private async ValueTask<RpcResponse> ResetAsync(JsonObject body, RpcContext context)
    {
        await _session.ResetAsync(context.CancellationToken).ConfigureAwait(false);
        ClearVerifier();
        return new RpcResponse(new JsonObject(), "device_info");
    }

    private async ValueTask<RpcNode> CreateAccountsAsync(RpcContext context)
    {
        if (_session.IsLocked)
        {
            throw new AuthRequiredException();
        }

        return await CredentialsNode.CreateAsync(_session, context).ConfigureAwait(false);
    }

    private byte[] GetKey(JsonObject body)
    {
        var key = body.GetOptionalBytes("key");
        var password = body.GetOptionalString("password");
        return (key, password) switch
        {
            ({ }, { }) => throw new InvalidParametersException("Only one of 'key' and 'password' can be provided."),
            (null, { } p) => DeriveFromPassword(p),
            ({ } k, null) => k,
            _ => throw new InvalidParametersException("One of 'key' and 'password' must be provided."),
        };
    }

    private byte[] DeriveFromPassword(string password)
    {
        var bytes = Encoding.UTF8.GetBytes(password);
        try
        {
            return _session.DeriveKey(bytes);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(bytes);
        }
    }

    private void SetVerifier(ReadOnlySpan<byte> key)
    {
        ClearVerifier();
        var salt = RandomNumberGenerator.GetBytes(32);
        _keyVerifier = (salt, HMACSHA256.HashData(salt, key));
    }

    private void ClearVerifier()
    {
        if (_keyVerifier is var (salt, digest))
        {
            CryptographicOperations.ZeroMemory(salt);
            CryptographicOperations.ZeroMemory(digest);
        }

        _keyVerifier = null;
    }
}
