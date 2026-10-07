using System.Runtime.InteropServices;
using System.Security.Principal;

namespace Yubico.Authenticator.Helper.Nodes;

internal static partial class Platform
{
    public static bool IsAdmin()
    {
        if (OperatingSystem.IsWindows())
        {
            using var identity = WindowsIdentity.GetCurrent();
            return new WindowsPrincipal(identity).IsInRole(WindowsBuiltInRole.Administrator);
        }

        return GetEuid() == 0;
    }

    [LibraryImport("libc", EntryPoint = "geteuid")]
    [DefaultDllImportSearchPaths(DllImportSearchPath.SafeDirectories)]
    private static partial uint GetEuid();
}
