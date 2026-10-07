using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// NFC readers. Not implemented in the prototype: always reports no readers, which the app
/// renders as "no NFC reader". Port target: ReadersNode/ReaderDeviceNode in device.py.
/// </summary>
internal sealed class ReadersNode : RpcNode
{
    public ReadersNode()
    {
        AddAction("scan", (_, _) => ValueTask.FromResult(new RpcResponse(new JsonObject())), closesChild: false);
    }
}
