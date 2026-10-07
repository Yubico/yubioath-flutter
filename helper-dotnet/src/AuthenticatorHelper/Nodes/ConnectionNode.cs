using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Nodes.Fido;
using Yubico.Authenticator.Helper.Nodes.Oath;
using Yubico.Authenticator.Helper.Nodes.Piv;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core;
using Yubico.YubiKit.Core.Abstractions;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Native.Desktop.SCard;
using Yubico.YubiKit.Core.Protocols.Fido.Hid;
using Yubico.YubiKit.Core.Sessions;
using Yubico.YubiKit.Core.Native;
using Yubico.YubiKit.Core.Protocols.SmartCard.Apdu;
using Yubico.YubiKit.Core.Transports.SmartCard;
using Yubico.YubiKit.Fido2.Ctap;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// One open USB interface (["usb", serial, "ccid" | "fido" | "otp"]) and the applications reachable
/// through it. Port of ConnectionNode in device.py.
/// </summary>
internal sealed class ConnectionNode : RpcNode
{
    private const short SwInsNotSupported = 0x6D00;
    private const string Name = "connection";

    private readonly IYubiKey _device;
    private readonly DeviceInfo _info;
    private bool _connectionDisposed;

    public ConnectionNode(IYubiKey device, IConnection connection, DeviceInfo info, string kind)
    {
        _device = device;
        _info = info;
        Connection = connection;
        var enabled = info.UsbEnabled;
        var isSmartCard = connection is ISmartCardConnection;

        SessionOptions = TouchSignalPrompt.CreateOptions(
            info.VersionQualifier.Type != VersionQualifierType.Final ? DeviceInfoJson.EffectiveVersion(info) : null);
        AddChild("management", ctx => ManagementNode.CreateAsync(Connection, SessionOptions, ctx));
        AddChild("oath", ctx => OathNode.CreateAsync((ISmartCardConnection)Connection, SessionOptions, ctx),
            () => isSmartCard && enabled.HasFlag(DeviceCapabilities.Oath));
        AddChild("piv", ctx => PivNode.CreateAsync((ISmartCardConnection)Connection, SessionOptions, ctx),
            () => isSmartCard && enabled.HasFlag(DeviceCapabilities.Piv));
        AddChild("ctap2", ctx => Ctap2Node.CreateAsync(this, ctx),
            () => enabled.HasFlag(DeviceCapabilities.Fido2)
                && (connection is IFidoHidConnection || (isSmartCard && ((int)enabled & 0x1000) != 0)));
        Kind = kind;
    }

    public IConnection Connection { get; private set; }

    public IYubiKey Device => _device;

    public SessionCreationOptions SessionOptions { get; }

    public string Kind { get; }

    /// <summary>
    /// True for exceptions meaning the transport itself failed (key removed, reader reset,
    /// handle invalidated), as opposed to an application-level error.
    /// </summary>
    public static bool IsTransportFailure(Exception e) =>
        e is SCardException or PlatformApiException or PlatformInteropException or IOException;

    /// <summary>Closes and reopens the connection, e.g. after the key was reinserted for a FIDO reset.</summary>
    public async ValueTask<IConnection> ReconnectAsync(IYubiKey device, CancellationToken cancellationToken)
    {
        await DisposeConnectionAsync().ConfigureAwait(false);
        Connection = Connection is IFidoHidConnection
            ? await device.ConnectAsync<IFidoHidConnection>(cancellationToken).ConfigureAwait(false)
            : await device.ConnectAsync<ISmartCardConnection>(cancellationToken).ConfigureAwait(false);
        _connectionDisposed = false;
        return Connection;
    }

    public async ValueTask DisposeConnectionAsync()
    {
        _connectionDisposed = true;
        try
        {
            await Connection.DisposeAsync().ConfigureAwait(false);
        }
        catch (Exception e)
        {
            Log.Warning(Name, "Error closing connection", e);
        }
    }

    public ValueTask CloseSessionAsync() => CloseChildAsync();

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        if (_connectionDisposed)
        {
            // An interrupted FIDO reset left this interface without a connection.
            throw new ChildResetException("Connection was closed");
        }

        try
        {
            return await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
        }
        catch (Exception e) when (IsTransportFailure(e))
        {
            Log.Error(Name, "Connection error", e);
            throw new ChildResetException(e.Message);
        }
        catch (ApduException e) when (e.SW == SwInsNotSupported)
        {
            throw new ChildResetException($"SW: {e.SW:x4}");
        }
        catch (CtapException e) when (e.Status == CtapStatus.ChannelBusy)
        {
            throw new ChildResetException(e.Message);
        }
    }

    public override async ValueTask CloseAsync()
    {
        await base.CloseAsync().ConfigureAwait(false);
        await DisposeConnectionAsync().ConfigureAwait(false);
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(new JsonObject
        {
            ["version"] = DeviceInfoJson.Version(DeviceInfoJson.EffectiveVersion(_info)),
            ["serial"] = _info.SerialNumber,
        });
}
