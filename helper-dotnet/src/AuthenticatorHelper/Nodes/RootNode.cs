using System.Reflection;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>Root of the RPC tree. Port of RootNode in helper/helper/device.py.</summary>
internal sealed class RootNode : RpcNode
{
    private readonly DevicesNode _usb = new();
    private readonly ReadersNode _nfc = new();

    public RootNode()
    {
        AddChild("usb", _ => ValueTask.FromResult<RpcNode>(_usb));
        AddChild("nfc", _ => ValueTask.FromResult<RpcNode>(_nfc));
        AddAction("logging", SetLogLevel, closesChild: false);
    }

    public static string Version =>
        typeof(RootNode).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion
            .Split('+')[0] ?? "0.0.0";

    public override async ValueTask CloseAsync()
    {
        await _usb.CloseAsync().ConfigureAwait(false);
        await _nfc.CloseAsync().ConfigureAwait(false);
        await base.CloseAsync().ConfigureAwait(false);
    }

    protected override ValueTask<JsonObject> GetDataAsync(RpcContext context) =>
        ValueTask.FromResult(new JsonObject
        {
            ["version"] = $"{Version}-dotnet",
            ["is_admin"] = Platform.IsAdmin(),
        });

    // The usb/nfc nodes are long-lived; switching between them must not close either one, but the
    // last one addressed is still tracked so that root actions close it (RootNode.get_child in device.py).
    protected override async ValueTask<RpcNode> GetChildAsync(string name, RpcContext context)
    {
        var child = await CreateChildAsync(name, context).ConfigureAwait(false);
        TrackChild(name, child);
        return child;
    }

    private static ValueTask<RpcResponse> SetLogLevel(JsonObject body, RpcContext context)
    {
        var level = Log.ParseLevel(body.GetString("level"));
        Log.MinimumLevel = level;
        Log.Info("helper", $"Log level set to: {level}");
        return ValueTask.FromResult(new RpcResponse(new JsonObject()));
    }
}
