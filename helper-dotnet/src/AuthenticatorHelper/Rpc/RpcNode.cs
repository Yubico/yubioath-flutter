using System.Text.Json.Nodes;

namespace Yubico.Authenticator.Helper.Rpc;

internal sealed record RpcResponse(JsonNode? Body, List<string> Flags)
{
    public RpcResponse(JsonNode? body, params string[] flags) : this(body, new List<string>(flags)) { }
}

/// <summary>Per-command context: cancellation (the app's "cancel" signal) and outgoing signals.</summary>
internal sealed class RpcContext(CancellationToken cancellationToken, Action<string, JsonObject> signal)
{
    private static readonly AsyncLocal<RpcContext?> CurrentContext = new();

    /// <summary>The command currently executing on this async flow (used by SDK user-presence callbacks).</summary>
    public static RpcContext? Current
    {
        get => CurrentContext.Value;
        set => CurrentContext.Value = value;
    }

    public CancellationToken CancellationToken { get; } = cancellationToken;

    public void Signal(string status, JsonObject? body = null) => signal(status, body ?? []);
}

internal delegate ValueTask<RpcResponse> RpcAction(JsonObject body, RpcContext context);

/// <summary>
/// A node in the RPC tree. A port of RpcNode in helper/helper/base.py: a node exposes actions and
/// children, keeps at most one open child, and closes that child when a sibling is addressed or when
/// an action that "closes_child" runs. The app addresses nodes with a target path, e.g.
/// ["usb", "125", "ccid", "oath", "accounts"].
/// </summary>
internal abstract class RpcNode
{
    private readonly SortedDictionary<string, ActionDefinition> _actions = new(StringComparer.Ordinal);
    private readonly SortedDictionary<string, ChildDefinition> _children = new(StringComparer.Ordinal);

    protected RpcNode()
    {
        AddAction("get", GetAsync, closesChild: true);
    }

    protected RpcNode? Child { get; private set; }

    protected string? ChildName { get; private set; }

    public bool Closed { get; private set; }

    protected void AddAction(string name, RpcAction action, bool closesChild = true, Func<bool>? condition = null) =>
        _actions[name] = new ActionDefinition(action, closesChild, condition);

    protected void AddChild(string name, Func<RpcContext, ValueTask<RpcNode>> factory, Func<bool>? condition = null) =>
        _children[name] = new ChildDefinition(factory, condition);

    public virtual async ValueTask<RpcResponse> CallAsync(
        string action, ReadOnlyMemory<string> target, JsonObject body, RpcContext context, List<string> traversed)
    {
        try
        {
            if (!target.IsEmpty)
            {
                var name = target.Span[0];
                traversed.Add(name);
                var child = await GetChildAsync(name, context).ConfigureAwait(false);
                return await child.CallAsync(action, target[1..], body, context, traversed).ConfigureAwait(false);
            }

            if (ListActions().Contains(action))
            {
                var definition = GetAction(action);
                if (definition.ClosesChild)
                {
                    await CloseChildAsync().ConfigureAwait(false);
                }

                return await definition.Action(body, context).ConfigureAwait(false);
            }

            var children = await ListChildrenAsync(context).ConfigureAwait(false);
            if (children.ContainsKey(action))
            {
                traversed.Add(action);
                var child = await GetChildAsync(action, context).ConfigureAwait(false);
                return await child.CallAsync("get", ReadOnlyMemory<string>.Empty, body, context, traversed)
                    .ConfigureAwait(false);
            }

            throw new NoSuchActionException(action);
        }
        catch (ChildResetException e)
        {
            await CloseChildAsync().ConfigureAwait(false);
            throw new StateResetException(e.Message, traversed);
        }
        catch (FormatException e)
        {
            throw new InvalidParametersException(e.Message);
        }
    }

    public virtual async ValueTask CloseAsync()
    {
        Closed = true;
        await CloseChildAsync().ConfigureAwait(false);
    }

    protected virtual ValueTask<JsonObject> GetDataAsync(RpcContext context) => ValueTask.FromResult(new JsonObject());

    protected virtual IReadOnlyList<string> ListActions() =>
        [.. _actions.Where(kv => kv.Value.Condition?.Invoke() ?? true).Select(kv => kv.Key)];

    protected virtual ValueTask<JsonObject> ListChildrenAsync(RpcContext context)
    {
        var result = new JsonObject();
        foreach (var (name, definition) in _children)
        {
            if (definition.Condition?.Invoke() ?? true)
            {
                result[name] = new JsonObject();
            }
        }

        return ValueTask.FromResult(result);
    }

    protected virtual ValueTask<RpcNode> CreateChildAsync(string name, RpcContext context)
    {
        if (_children.TryGetValue(name, out var definition) && (definition.Condition?.Invoke() ?? true))
        {
            return definition.Factory(context);
        }

        throw new NoSuchNodeException(name);
    }

    protected virtual async ValueTask<RpcNode> GetChildAsync(string name, RpcContext context)
    {
        if (Child is not null && ChildName != name)
        {
            await CloseChildAsync().ConfigureAwait(false);
        }

        if (Child is null || Child.Closed)
        {
            Child = await CreateChildAsync(name, context).ConfigureAwait(false);
            ChildName = name;
            Log.Debug(GetType().Name, $"created child: {name}");
        }

        return Child;
    }

    protected async ValueTask CloseChildAsync()
    {
        if (Child is null)
        {
            return;
        }

        Log.Debug(GetType().Name, $"close existing child: {ChildName}");
        try
        {
            await Child.CloseAsync().ConfigureAwait(false);
        }
        catch (Exception e)
        {
            Log.Warning(GetType().Name, "Error closing child", e);
        }

        Child = null;
        ChildName = null;
    }

    /// <summary>Records <paramref name="node"/> as the open child without closing the previous one.</summary>
    protected void TrackChild(string name, RpcNode node)
    {
        Child = node;
        ChildName = name;
    }

    /// <summary>Drops the child reference without closing it (the underlying device is already gone).</summary>
    protected void ForgetChild()
    {
        Child = null;
        ChildName = null;
    }

    private ActionDefinition GetAction(string name) =>
        _actions.TryGetValue(name, out var definition) && (definition.Condition?.Invoke() ?? true)
            ? definition
            : throw new NoSuchActionException(name);

    protected async ValueTask<RpcResponse> GetAsync(JsonObject body, RpcContext context)
    {
        var data = await GetDataAsync(context).ConfigureAwait(false);
        var children = await ListChildrenAsync(context).ConfigureAwait(false);
        return new RpcResponse(new JsonObject
        {
            ["data"] = data,
            ["actions"] = Json.Array(ListActions()),
            ["children"] = children,
        });
    }

    private sealed record ActionDefinition(RpcAction Action, bool ClosesChild, Func<bool>? Condition);

    private sealed record ChildDefinition(Func<RpcContext, ValueTask<RpcNode>> Factory, Func<bool>? Condition);
}
