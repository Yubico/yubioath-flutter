using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Abstractions;
using Yubico.YubiKit.Core.Devices;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// The "usb" node. Port of DevicesNode in device.py. The app polls <c>scan</c> every 500 ms and
/// only re-lists children when the returned <c>state</c> changes.
/// </summary>
internal sealed class DevicesNode : RpcNode
{
    private const string Name = "devices";

    private readonly Dictionary<string, IYubiKey> _mapping = new(StringComparer.Ordinal);
    private JsonObject _devices = [];
    private long _listState;
    private IReadOnlyList<IYubiKey>? _scanCache;
    private string? _failingConnection;
    private int _retries;

    public DevicesNode()
    {
        AddAction("scan", ScanAsync, closesChild: false);
    }

    public override async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        _scanCache = null;
        try
        {
            var response = await base.CallAsync(action, target, body, context, traversed).ConfigureAwait(false);
            if (response.Flags.Remove("device_closed"))
            {
                InvalidateListing();
            }

            return response;
        }
        catch (RpcException e) when (e is ConnectionException)
        {
            var key = e.Body.ToJsonString();
            if (key == _failingConnection)
            {
                _retries++;
            }
            else
            {
                _failingConnection = key;
                _retries = 0;
            }

            if (_retries > 2)
            {
                throw;
            }

            // Python raises ChildResetException here, which makes the root close this node: drop the
            // open device subtree and the id mapping so the next request re-enumerates.
            Log.Debug(Name, $"Connection failed, attempt to recover: {e.Message}");
            await CloseChildAsync().ConfigureAwait(false);
            InvalidateListing();
            throw new StateResetException(e.Message, traversed);
        }
        finally
        {
            _scanCache = null;
        }
    }

    public override async ValueTask CloseAsync()
    {
        InvalidateListing();
        await base.CloseAsync().ConfigureAwait(false);
    }

    protected override async ValueTask<JsonObject> GetDataAsync(RpcContext context)
    {
        var devices = await GetDevicesAsync(context.CancellationToken).ConfigureAwait(false);
        return StateOf(devices);
    }

    protected override async ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var devices = await GetDevicesAsync(context.CancellationToken).ConfigureAwait(false);
        var state = StateOf(devices)["state"]!.GetValue<long>();
        // State 0 means "nothing attached" and also "cache invalid", so it is never served from cache.
        if (state == _listState && state != 0)
        {
            return (JsonObject)_devices.DeepClone();
        }

        Log.Debug(Name, $"State changed (was={_listState}, now={state})");
        _devices = [];
        _mapping.Clear();
        var identified = 0;
        foreach (var device in devices)
        {
            var info = await UsbDeviceNode.TryReadInfoAsync(device, null, context.CancellationToken)
                .ConfigureAwait(false);
            var id = DeviceIdFor(device, info);
            _mapping[id] = device;
            if (info is { } i)
            {
                identified++;
                _devices[id] = new JsonObject
                {
                    ["pid"] = UsbPid.Of(device),
                    ["name"] = DeviceInfoJson.GetName(i, UsbPid.IsFidoOnly(device)),
                    ["serial"] = i.SerialNumber,
                };
            }
        }

        if (identified == devices.Count)
        {
            _listState = state;
        }
        else
        {
            Log.Warning(Name, "Not all devices identified");
            _listState = 0;
        }

        return (JsonObject)_devices.DeepClone();
    }

    protected override async ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context)
    {
        if (!_mapping.ContainsKey(name) && _listState == 0)
        {
            await ListChildrenAsync(context).ConfigureAwait(false);
        }

        if (!_mapping.TryGetValue(name, out var device))
        {
            throw new NoSuchNodeException(name);
        }

        return await UsbDeviceNode.CreateAsync(device, name, context.CancellationToken).ConfigureAwait(false);
    }

    private void InvalidateListing()
    {
        _listState = 0;
        _mapping.Clear();
        _devices = [];
    }

    private async ValueTask<RpcResponse> ScanAsync(JsonObject body, RpcContext context) =>
        new(await GetDataAsync(context).ConfigureAwait(false));

    private async ValueTask<IReadOnlyList<IYubiKey>> GetDevicesAsync(CancellationToken cancellationToken)
    {
        if (_scanCache is null)
        {
            var all = await YubiKeyManager.FindAllAsync(ConnectionType.All, forceRescan: true, cancellationToken)
                .ConfigureAwait(false);
            _scanCache = all;
        }

        return _scanCache;
    }

    /// <summary>
    /// A cheap fingerprint of the attached set, standing in for ykman's scan_devices() state.
    /// </summary>
    private static JsonObject StateOf(IReadOnlyList<IYubiKey> devices)
    {
        var pids = new SortedDictionary<int, int>();
        var fingerprint = new StringBuilder();
        foreach (var device in devices.OrderBy(d => d.DeviceId, StringComparer.Ordinal))
        {
            var pid = UsbPid.Of(device);
            pids[pid] = pids.GetValueOrDefault(pid) + 1;
            fingerprint.Append(device.DeviceId).Append('|').Append((int)device.AvailableConnections).Append(';');
        }

        long state = 0;
        if (devices.Count > 0)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(fingerprint.ToString()));
            state = BitConverter.ToInt64(hash, 0) & long.MaxValue;
        }

        var pidsJson = new JsonObject();
        foreach (var (pid, count) in pids)
        {
            pidsJson[pid.ToString(System.Globalization.CultureInfo.InvariantCulture)] = count;
        }

        return new JsonObject { ["state"] = state, ["pids"] = pidsJson };
    }

    private static string DeviceIdFor(IYubiKey device, DeviceInfo? info)
    {
        if ((info?.SerialNumber ?? device.SerialNumber) is { } serial)
        {
            return serial.ToString(System.Globalization.CultureInfo.InvariantCulture);
        }

        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(device.DeviceId));
        return Convert.ToHexStringLower(hash)[..16];
    }
}

/// <summary>
/// The SDK does not expose the USB product id, so it is reconstructed from the exposed interfaces
/// using the YubiKey 4/5 PID scheme (0x0400 | OTP=1 | FIDO=2 | CCID=4).
/// </summary>
internal static class UsbPid
{
    public static int Of(IYubiKey device)
    {
        var mask = 0;
        if (device.SupportsConnection(ConnectionType.HidOtp))
        {
            mask |= 0x01;
        }

        if (device.SupportsConnection(ConnectionType.HidFido))
        {
            mask |= 0x02;
        }

        if (device.SupportsConnection(ConnectionType.SmartCard))
        {
            mask |= 0x04;
        }

        return 0x0400 | mask;
    }

    public static bool IsFidoOnly(IYubiKey device) => Of(device) == 0x0402;
}
