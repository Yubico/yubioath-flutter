using System.Text.Json.Nodes;

namespace Yubico.Authenticator.Helper.Rpc;

/// <summary>
/// Encoding helpers that reproduce Python's json.dumps output for the types the Python helper
/// returns: bytes as lowercase hex, enums as ints, version tuples as lists. Parameter readers
/// turn type mismatches into <c>invalid-command</c>, like the Python helper does for ValueError.
/// </summary>
internal static class Json
{
    public static JsonArray Array(IEnumerable<string> values) => [.. values.Select(v => (JsonNode?)v)];

    public static JsonArray Array(IEnumerable<int> values) => [.. values.Select(v => (JsonNode?)v)];

    public static string Hex(ReadOnlySpan<byte> value) => Convert.ToHexStringLower(value);

    public static JsonNode? HexOrNull(ReadOnlyMemory<byte>? value) =>
        value is { } v ? Convert.ToHexStringLower(v.Span) : null;

    public static JsonArray Version(int major, int minor, int patch) =>
        new(JsonValue.Create(major), JsonValue.Create(minor), JsonValue.Create(patch));

    public static string GetString(this JsonObject body, string key) =>
        body.GetOptionalString(key) ?? throw new InvalidParametersException($"missing '{key}'");

    public static string? GetOptionalString(this JsonObject body, string key) => Get<string>(body, key);

    public static bool GetBool(this JsonObject body, string key, bool fallback = false) =>
        body[key] is null ? fallback : Get<bool>(body, key);

    public static int GetInt(this JsonObject body, string key) =>
        body.GetOptionalInt(key) ?? throw new InvalidParametersException($"missing '{key}'");

    public static int? GetOptionalInt(this JsonObject body, string key) =>
        body[key] is null ? null : Get<int>(body, key);

    public static long? GetOptionalLong(this JsonObject body, string key) =>
        body[key] is null ? null : Get<long>(body, key);

    public static byte[] GetBytes(this JsonObject body, string key) =>
        GetOptionalBytes(body, key) ?? throw new InvalidParametersException($"missing '{key}'");

    public static byte[]? GetOptionalBytes(this JsonObject body, string key)
    {
        var hex = body.GetOptionalString(key);
        if (hex is null)
        {
            return null;
        }

        try
        {
            return Convert.FromHexString(hex);
        }
        catch (FormatException)
        {
            throw new InvalidParametersException($"'{key}' is not valid hex");
        }
    }

    private static T? Get<T>(JsonObject body, string key)
    {
        if (body[key] is not { } node)
        {
            return default;
        }

        try
        {
            return node.GetValue<T>();
        }
        catch (Exception e) when (e is InvalidOperationException or FormatException)
        {
            throw new InvalidParametersException($"'{key}' has the wrong type");
        }
    }
}
