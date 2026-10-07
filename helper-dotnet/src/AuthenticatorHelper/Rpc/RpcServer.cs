using System.Text.Json;
using System.Text.Json.Nodes;

namespace Yubico.Authenticator.Helper.Rpc;

/// <summary>
/// The request loop. A port of process() in helper/helper/__init__.py:
/// one command runs at a time; while it runs, the reader keeps consuming lines so that a
/// <c>{"kind": "signal", "status": "cancel"}</c> can cancel it. An empty line or EOF ends the loop.
/// </summary>
internal sealed class RpcServer(RpcNode root, TextReader input, Action<string> output)
{
    private readonly Lock _writeLock = new();

    public async Task RunAsync()
    {
        Task current = Task.CompletedTask;
        CancellationTokenSource? currentCancel = null;

        try
        {
            while (true)
            {
                var line = await input.ReadLineAsync().ConfigureAwait(false);
                if (string.IsNullOrWhiteSpace(line))
                {
                    break;
                }

                JsonObject request;
                string? kind;
                try
                {
                    request = JsonNode.Parse(line)?.AsObject() ?? throw new JsonException("Empty request");
                    kind = (request["kind"] as JsonValue)?.TryGetValue<string>(out var k) == true ? k : null;
                }
                catch (Exception e) when (e is JsonException or InvalidOperationException)
                {
                    SendError("invalid-command", e.Message, []);
                    continue;
                }

                (current, currentCancel) = await DispatchAsync(request, kind, line, current, currentCancel)
                    .ConfigureAwait(false);
            }
        }
        finally
        {
            currentCancel?.Cancel();
            await current.ConfigureAwait(false);
            currentCancel?.Dispose();
            await root.CloseAsync().ConfigureAwait(false);
        }
    }

    private async Task<(Task Current, CancellationTokenSource? Cancel)> DispatchAsync(
        JsonObject request, string? kind, string line, Task current, CancellationTokenSource? currentCancel)
    {
        switch (kind)
        {
            case "signal":
                if ((request["status"] as JsonValue)?.TryGetValue<string>(out var status) == true && status == "cancel")
                {
                    Log.Debug("helper", "Got cancel signal!");
                    currentCancel?.Cancel();
                }
                else
                {
                    Log.Error("helper", $"Unhandled signal: {line}");
                }

                break;
            case "command":
                await current.ConfigureAwait(false);
                currentCancel?.Dispose();
                currentCancel = new CancellationTokenSource();
                var token = currentCancel.Token;
                current = Task.Run(() => HandleCommandAsync(request, token));
                break;
            default:
                SendError("invalid-command", "Unsupported request type", []);
                break;
        }

        return (current, currentCancel);
    }

    private async Task HandleCommandAsync(JsonObject request, CancellationToken cancellationToken)
    {
        try
        {
            var action = request["action"]?.GetValue<string>() ?? throw new InvalidParametersException("missing action");
            var target = request["target"]?.AsArray().Select(n => n!.GetValue<string>()).ToArray() ?? [];
            var body = request["body"] as JsonObject ?? [];
            var context = new RpcContext(cancellationToken, SendSignal);
            RpcContext.Current = context;
            var response = await root.CallAsync(action, target, body, context, []).ConfigureAwait(false);
            Send(new JsonObject
            {
                ["kind"] = "success",
                ["body"] = response.Body ?? new JsonObject(),
                ["flags"] = Json.Array(response.Flags),
            });
        }
        catch (RpcException e)
        {
            SendError(e.Status, e.Message, e.Body);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            SendError("cancelled", "Command was cancelled", []);
        }
        catch (Exception e)
        {
            Log.Error("helper", "Unhandled exception", e);
            SendError("exception", $"{e.GetType().Name}({e.Message})", []);
        }
    }

    private void SendSignal(string status, JsonObject body) =>
        Send(new JsonObject { ["kind"] = "signal", ["status"] = status, ["body"] = body });

    private void SendError(string status, string message, JsonObject body) =>
        Send(new JsonObject
        {
            ["kind"] = "error",
            ["status"] = status,
            ["message"] = message,
            ["body"] = body.Parent is null ? body : body.DeepClone(),
        });

    private void Send(JsonObject message)
    {
        var line = message.ToJsonString();
        lock (_writeLock)
        {
            output(line);
        }
    }
}
