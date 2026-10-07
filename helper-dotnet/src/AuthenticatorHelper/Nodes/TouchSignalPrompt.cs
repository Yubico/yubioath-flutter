using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Credentials;
using Yubico.YubiKit.Core.Devices;
using Yubico.YubiKit.Core.Sessions;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// Bridges the SDK's user-presence callback to the app's "touch" signal, which shows the
/// "touch your YubiKey" prompt. Replaces the 0.5 s timers the Python helper uses.
/// </summary>
internal sealed class TouchSignalPrompt : IUserPresencePrompt
{
    public static readonly TouchSignalPrompt Instance = new();

    /// <summary>
    /// Options for every applet session. Pre-release keys report firmware 0.0.1 from the applets, so
    /// the version from the device's version qualifier is passed as an override (yubikit's Python
    /// helper does the same globally with _override_version).
    /// </summary>
    public static SessionCreationOptions CreateOptions(FirmwareVersion? firmwareVersionOverride) =>
        new() { UserPresencePrompt = Instance, FirmwareVersionOverride = firmwareVersionOverride };

    public ValueTask OnUserPresenceRequestedAsync(UserPresenceContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);
        if (context.Operation == UserPresenceOperations.Fido2.Reset)
        {
            RpcContext.Current?.Signal("reset", new System.Text.Json.Nodes.JsonObject { ["state"] = "touch" });
        }
        else
        {
            RpcContext.Current?.Signal("touch");
        }

        return ValueTask.CompletedTask;
    }
}
