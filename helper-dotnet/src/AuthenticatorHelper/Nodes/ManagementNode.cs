using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core;
using Yubico.YubiKit.Core.Abstractions;
using Yubico.YubiKit.Core.Sessions;
using Yubico.YubiKit.Core.Transports.SmartCard;
using Yubico.YubiKit.Management;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>Port of ManagementNode in helper/helper/management.py.</summary>
internal sealed class ManagementNode : RpcNode
{
    private readonly ManagementSession _session;

    private ManagementNode(ManagementSession session, bool isSmartCard)
    {
        _session = session;
        AddAction("configure", ConfigureAsync);
        AddAction("device_reset", DeviceResetAsync, condition: () => isSmartCard);
    }

    public static async ValueTask<RpcNode> CreateAsync(
        IConnection connection, SessionCreationOptions options, RpcContext context)
    {
        var session = await ManagementSession.CreateAsync(connection, options, context.CancellationToken)
            .ConfigureAwait(false);
        return new ManagementNode(session, connection is ISmartCardConnection);
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        await _session.DisposeAsync().ConfigureAwait(false);
    }

    protected override async ValueTask<JsonObject> GetDataAsync(RpcContext context)
    {
        var info = await _session.GetDeviceInfoAsync(context.CancellationToken).ConfigureAwait(false);
        return DeviceInfoJson.ToJson(info);
    }

    private async ValueTask<RpcResponse> ConfigureAsync(JsonObject body, RpcContext context)
    {
        var capabilities = new Dictionary<Transport, int>();
        if (body["enabled_capabilities"] is JsonObject enabled)
        {
            foreach (var (transport, value) in enabled)
            {
                capabilities[transport == "nfc" ? Transport.Nfc : Transport.Usb] = value!.GetValue<int>();
            }
        }

        var config = new DeviceConfig
        {
            EnabledCapabilities = capabilities,
            AutoEjectTimeout = (ushort?)body.GetOptionalInt("auto_eject_timeout"),
            ChallengeResponseTimeout = (byte?)body.GetOptionalInt("challenge_response_timeout"),
            DeviceFlags = body.GetOptionalInt("device_flags") is int flags and not 0 ? (byte)flags : null,
        };
        var reboot = body.GetBool("reboot");
        var options = new SetDeviceConfigOptions
        {
            Reboot = reboot,
            CurrentLockCode = body.GetOptionalBytes("cur_lock_code"),
            NewLockCode = body.GetOptionalBytes("new_lock_code"),
        };
        await _session.SetDeviceConfigAsync(config, options, context.CancellationToken).ConfigureAwait(false);

        if (!reboot)
        {
            return new RpcResponse(new JsonObject(), "device_info");
        }

        // The key re-enumerates; give it a moment like _await_reboot() does in the Python helper.
        await Task.Delay(TimeSpan.FromSeconds(2), context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject(), "device_info", "device_closed");
    }

    private async ValueTask<RpcResponse> DeviceResetAsync(JsonObject body, RpcContext context)
    {
        await _session.ResetDeviceAsync(context.CancellationToken).ConfigureAwait(false);
        return new RpcResponse(new JsonObject(), "device_info");
    }
}
