using System.Globalization;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Yubico.Authenticator.Helper.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core;

// Entry point. Same command line as helper/authenticator-helper.py:
//   authenticator-helper              RPC over stdin/stdout, logs as JSON lines on stderr
//   authenticator-helper --tcp P N    connect to 127.0.0.1:P, send nonce N, then RPC over the socket
//                                     with "O"/"E" line prefixes (used by the elevated Windows helper)

YubiKitLogging.Configure(new Log.LoggerFactory());

var tcpIndex = Array.IndexOf(args, "--tcp");
if (tcpIndex >= 0 && args.Length > tcpIndex + 2)
{
    var port = int.Parse(args[tcpIndex + 1], CultureInfo.InvariantCulture);
    var nonce = args[tcpIndex + 2];
    using var client = new TcpClient();
    await client.ConnectAsync(IPAddress.Loopback, port).ConfigureAwait(false);
    var stream = client.GetStream();
    var writer = new StreamWriter(stream, new UTF8Encoding(false)) { AutoFlush = true, NewLine = "\n" };
    var socketLock = new Lock();
    void WriteLine(string line)
    {
        lock (socketLock)
        {
            writer.WriteLine(line);
        }
    }

    WriteLine(nonce);
    Log.UseSink(line => WriteLine("E" + line));
    using var reader = new StreamReader(stream, new UTF8Encoding(false));
    await new RpcServer(new RootNode(), reader, line => WriteLine("O" + line)).RunAsync().ConfigureAwait(false);
}
else
{
    var utf8 = new UTF8Encoding(false);
    using var stdin = new StreamReader(Console.OpenStandardInput(), utf8);
    using var stdout = new StreamWriter(Console.OpenStandardOutput(), utf8) { AutoFlush = true, NewLine = "\n" };
    using var stderr = new StreamWriter(Console.OpenStandardError(), utf8) { AutoFlush = true, NewLine = "\n" };
    Log.UseSink(stderr.WriteLine);
    await new RpcServer(new RootNode(), stdin, stdout.WriteLine).RunAsync().ConfigureAwait(false);
}
