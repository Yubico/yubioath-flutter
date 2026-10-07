using System.Text.Json.Nodes;

namespace Yubico.Authenticator.Helper.Rpc;

/// <summary>An error returned to the app as <c>{"kind": "error", ...}</c>. Mirrors helper/helper/base.py.</summary>
internal class RpcException(string status, string message, JsonObject? body = null) : Exception(message)
{
    public string Status { get; } = status;
    public JsonObject Body { get; } = body ?? [];
}

internal sealed class InvalidParametersException(string message)
    : RpcException("invalid-command", $"Invalid parameters: {message}");

internal sealed class NoSuchActionException(string name)
    : RpcException("invalid-command", $"No such action: {name}");

internal sealed class NoSuchNodeException(string name)
    : RpcException("invalid-command", $"No such node: {name}");

internal sealed class StateResetException(string? message, IReadOnlyList<string> path)
    : RpcException("state-reset", message ?? "State reset in node", new JsonObject { ["path"] = Json.Array(path) });

internal sealed class TimeoutException()
    : RpcException("timeout", "Command timed out waiting for user action");

internal sealed class AuthRequiredException()
    : RpcException("auth-required", "Authentication is required");

internal sealed class PinComplexityException()
    : RpcException("pin-complexity", "PIN does not meet complexity requirements");

internal sealed class ConnectionException(string device, string connection, Exception cause)
    : RpcException(
        "connection-error",
        $"Error connecting to {connection} interface",
        new JsonObject { ["device"] = device, ["connection"] = connection, ["exc_type"] = cause.GetType().Name });

internal sealed class FidoBlockedException(string connection)
    : RpcException("fido-blocked-error", "FIDO access required admin", new JsonObject { ["connection"] = connection });

/// <summary>
/// Thrown inside a node when its session is no longer usable. The parent closes the child and the
/// app receives <c>state-reset</c>, which makes it re-read the node. Mirrors ChildResetException.
/// </summary>
internal sealed class ChildResetException(string message) : Exception(message);
