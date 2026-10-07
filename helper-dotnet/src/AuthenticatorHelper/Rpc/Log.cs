using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace Yubico.Authenticator.Helper.Rpc;

/// <summary>
/// Writes log records in the format lib/desktop/rpc.dart parses from the helper's stderr:
/// one JSON object per line with time, name, level (Python level names), message and exc_text.
/// SDK logging is routed here through <see cref="LoggerFactory"/>.
/// </summary>
internal static class Log
{
    private static readonly Lock WriteLock = new();
    private static Action<string> _sink = line => Console.Error.WriteLine(line);

    public static LogLevel MinimumLevel { get; set; } = LogLevel.Warning;

    public static void UseSink(Action<string> sink) => _sink = sink;

    /// <summary>Maps the level names the app sends in the "logging" action.</summary>
    public static LogLevel ParseLevel(string level) => level.ToUpperInvariant() switch
    {
        "TRAFFIC" => LogLevel.Trace,
        "DEBUG" => LogLevel.Debug,
        "INFO" => LogLevel.Information,
        "WARNING" => LogLevel.Warning,
        "ERROR" => LogLevel.Error,
        "CRITICAL" => LogLevel.Critical,
        _ => throw new InvalidParametersException($"unknown log level '{level}'"),
    };

    public static void Debug(string name, string message) => Write(LogLevel.Debug, name, message, null);

    public static void Info(string name, string message) => Write(LogLevel.Information, name, message, null);

    public static void Warning(string name, string message, Exception? exception = null) =>
        Write(LogLevel.Warning, name, message, exception);

    public static void Error(string name, string message, Exception? exception = null) =>
        Write(LogLevel.Error, name, message, exception);

    public static void Write(LogLevel level, string name, string message, Exception? exception)
    {
        if (level < MinimumLevel || level == LogLevel.None)
        {
            return;
        }

        using var buffer = new MemoryStream();
        using (var writer = new Utf8JsonWriter(buffer))
        {
            writer.WriteStartObject();
            writer.WriteNumber("time", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() / 1000.0);
            writer.WriteString("name", name);
            writer.WriteString("level", PythonLevelName(level));
            writer.WriteString("message", message);
            if (exception is not null)
            {
                writer.WriteString("exc_text", exception.ToString());
            }

            writer.WriteEndObject();
        }

        var line = System.Text.Encoding.UTF8.GetString(buffer.ToArray());
        lock (WriteLock)
        {
            _sink(line);
        }
    }

    private static string PythonLevelName(LogLevel level) => level switch
    {
        LogLevel.Trace => "TRAFFIC",
        LogLevel.Debug => "DEBUG",
        LogLevel.Information => "INFO",
        LogLevel.Warning => "WARNING",
        LogLevel.Error => "ERROR",
        _ => "CRITICAL",
    };

    /// <summary>Adapter that lets SDK components (YubiKitLogging) log through this sink.</summary>
    public sealed class LoggerFactory : ILoggerFactory, ILoggerProvider
    {
        public ILogger CreateLogger(string categoryName) => new Logger(categoryName);

        public void AddProvider(ILoggerProvider provider) { }

        public void Dispose() { }

        private sealed class Logger(string name) : ILogger
        {
            public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

            public bool IsEnabled(LogLevel logLevel) => logLevel >= MinimumLevel && logLevel != LogLevel.None;

            public void Log<TState>(
                LogLevel logLevel, EventId eventId, TState state, Exception? exception,
                Func<TState, Exception?, string> formatter)
            {
                if (IsEnabled(logLevel))
                {
                    Write(logLevel, name, formatter(state, exception), exception);
                }
            }
        }
    }
}
