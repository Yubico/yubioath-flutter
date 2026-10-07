using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Abstractions;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Protocols.Fido.Hid;
using Yubico.YubiKit.Core.Transports.Hid;
using Yubico.YubiKit.Core.Transports.SmartCard;
using Yubico.YubiKit.Management;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// One USB YubiKey: ["usb", "&lt;serial&gt;"]. Port of UsbDeviceNode/AbstractDeviceNode in device.py.
/// Children are the USB interfaces (ccid, fido, otp), each holding one open connection.
/// </summary>
internal sealed class UsbDeviceNode : RpcNode
{
    private const string Name = "device";

    private static readonly ConnectionType[] ReadInfoOrder =
        [ConnectionType.SmartCard, ConnectionType.HidOtp, ConnectionType.HidFido];

    private readonly IYubiKey _device;
    private readonly string _id;
    private DeviceInfo? _info;
    private JsonObject? _data;

    private UsbDeviceNode(IYubiKey device, string id)
    {
        _device = device;
        _id = id;
        AddChild("ccid", ct => OpenAsync<ISmartCardConnection>("ccid", ct), () => device.SupportsConnection(ConnectionType.SmartCard));
        AddChild("otp", ct => OpenAsync<IOtpHidConnection>("otp", ct), () => device.SupportsConnection(ConnectionType.HidOtp));
        AddChild("fido", ct => OpenAsync<IFidoHidConnection>("fido", ct), () => device.SupportsConnection(ConnectionType.HidFido));
    }

    public static async ValueTask<UsbDeviceNode> CreateAsync(IYubiKey device, string id, CancellationToken cancellationToken)
    {
        var node = new UsbDeviceNode(device, id);
        await node.RefreshDataAsync(cancellationToken).ConfigureAwait(false);
        return node;
    }

    /// <summary>
    /// Reads DeviceInfo through the Management application, trying SmartCard, OTP and then FIDO
    /// like read_info() in yubikit.support. Reuses <paramref name="existing"/> when provided.
    /// </summary>
    public static async Task<DeviceInfo?> TryReadInfoAsync(
        IYubiKey device, IConnection? existing, CancellationToken cancellationToken)
    {
        if (existing is not null)
        {
            try
            {
                return await ReadInfoAsync(existing, cancellationToken).ConfigureAwait(false);
            }
            catch (Exception e) when (e is not OperationCanceledException)
            {
                Log.Warning(Name, $"Unable to use {existing.GetType().Name}", e);
            }
        }

        foreach (var type in ReadInfoOrder)
        {
            if (!device.SupportsConnection(type))
            {
                continue;
            }

            try
            {
                await using var connection = await ConnectAsync(device, type, cancellationToken).ConfigureAwait(false);
                return await ReadInfoAsync(connection, cancellationToken).ConfigureAwait(false);
            }
            catch (Exception e) when (e is not OperationCanceledException)
            {
                Log.Warning(Name, $"Unable to connect via {type}", e);
            }
        }

        return null;
    }

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        try
        {
            var response = await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
            if (response.Flags.Contains("device_closed"))
            {
                await CloseAsync().ConfigureAwait(false);
                return response;
            }

            if (response.Flags.Contains("device_info"))
            {
                var old = _data?["info"]?.ToJsonString();
                await RefreshDataAsync(context.CancellationToken).ConfigureAwait(false);
                if (old == _data?["info"]?.ToJsonString())
                {
                    response.Flags.Remove("device_info");
                }
            }

            return response;
        }
        catch (Exception e) when (ConnectionNode.IsTransportFailure(e))
        {
            Log.Error(Name, "Device error", e);
            var name = ChildName;
            ForgetChild();
            throw new NoSuchNodeException(name ?? _id);
        }
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        _data is not null
            ? ValueTask.FromResult((JsonObject)_data.DeepClone())
            : throw new ChildResetException("Unable to read device data");

    private static async Task<DeviceInfo> ReadInfoAsync(IConnection connection, CancellationToken cancellationToken)
    {
        await using var session = await ManagementSession.CreateAsync(connection, null, cancellationToken)
            .ConfigureAwait(false);
        return await session.GetDeviceInfoAsync(cancellationToken).ConfigureAwait(false);
    }

    private static async Task<IConnection> ConnectAsync(IYubiKey device, ConnectionType type, CancellationToken ct) =>
        type switch
        {
            ConnectionType.SmartCard => await device.ConnectAsync<ISmartCardConnection>(ct).ConfigureAwait(false),
            ConnectionType.HidOtp => await device.ConnectAsync<IOtpHidConnection>(ct).ConfigureAwait(false),
            _ => await device.ConnectAsync<IFidoHidConnection>(ct).ConfigureAwait(false),
        };

    private async ValueTask RefreshDataAsync(CancellationToken cancellationToken)
    {
        IConnection? existing = null;
        if (Child is ConnectionNode { Closed: false } connectionNode)
        {
            await connectionNode.CloseSessionAsync().ConfigureAwait(false);
            existing = connectionNode.Connection;
        }

        var info = await TryReadInfoAsync(_device, existing, cancellationToken).ConfigureAwait(false);
        if (info is not { } i)
        {
            _info = null;
            _data = null;
            await CloseAsync().ConfigureAwait(false);
            return;
        }

        _info = i;
        _data = new JsonObject
        {
            ["pid"] = UsbPid.Of(_device),
            ["name"] = DeviceInfoJson.GetName(i, UsbPid.IsFidoOnly(_device)),
            ["transport"] = "usb",
            ["info"] = DeviceInfoJson.ToJson(i),
        };
    }

    private async ValueTask<RpcNode> OpenAsync<TConnection>(string kind, RpcContext context)
        where TConnection : class, IConnection
    {
        if (Environment.GetEnvironmentVariable($"_YK_NO_{kind.ToUpperInvariant()}") is not null)
        {
            Log.Info(Name, "Connection type blocked for testing");
            throw new ConnectionException(_id, kind, new InvalidOperationException("blocked"));
        }

        if (_info is not { } info)
        {
            throw new ChildResetException("Unable to read device data");
        }

        try
        {
            var connection = await _device.ConnectAsync<TConnection>(context.CancellationToken).ConfigureAwait(false);
            return new ConnectionNode(_device, connection, info, kind);
        }
        catch (UnauthorizedAccessException) when (OperatingSystem.IsWindows() && kind == "fido" && !Platform.IsAdmin())
        {
            throw new FidoBlockedException("fido");
        }
        catch (Exception e) when (e is not OperationCanceledException and not RpcException)
        {
            Log.Warning(Name, "Error opening connection", e);
            throw new ConnectionException(_id, kind, e);
        }
    }
}
