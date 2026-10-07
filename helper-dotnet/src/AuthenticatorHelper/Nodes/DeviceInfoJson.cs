using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Core.Devices;

namespace Yubico.Authenticator.Helper.Nodes;

/// <summary>
/// Serializes the SDK's DeviceInfo into the shape of dataclasses.asdict(yubikit DeviceInfo), which is
/// what lib/management/models.dart parses, and ports yubikit.support.get_name.
/// </summary>
internal static class DeviceInfoJson
{
    public static JsonObject ToJson(DeviceInfo info)
    {
        var nfcSupported = info.NfcSupported != DeviceCapabilities.None;
        var enabled = new JsonObject { ["usb"] = (int)info.UsbEnabled };
        var supported = new JsonObject { ["usb"] = (int)info.UsbSupported };
        if (nfcSupported)
        {
            enabled["nfc"] = (int)info.NfcEnabled;
            supported["nfc"] = (int)info.NfcSupported;
        }

        return new JsonObject
        {
            ["config"] = new JsonObject
            {
                ["enabled_capabilities"] = enabled,
                ["auto_eject_timeout"] = (int)info.AutoEjectTimeout,
                ["challenge_response_timeout"] = info.ChallengeResponseTimeout.IsEmpty
                    ? null
                    : (int)info.ChallengeResponseTimeout.Span[0],
                ["device_flags"] = (int)info.DeviceFlags,
                ["nfc_restricted"] = info.IsNfcRestricted,
            },
            ["serial"] = info.SerialNumber,
            ["version"] = Version(EffectiveVersion(info)),
            ["form_factor"] = (int)info.FormFactor,
            ["supported_capabilities"] = supported,
            ["is_locked"] = info.IsLocked,
            ["is_fips"] = info.IsFips,
            ["is_sky"] = info.IsSky,
            ["part_number"] = info.PartNumber,
            ["fips_capable"] = (int)info.FipsCapabilities,
            ["fips_approved"] = (int)info.FipsApproved,
            ["pin_complexity"] = info.HasPinComplexity,
            ["reset_blocked"] = (int)info.ResetBlocked,
            ["fps_version"] = info.FpsVersion is { } fps ? Version(fps) : null,
            ["stm_version"] = info.StmVersion is { } stm ? Version(stm) : null,
            ["version_qualifier"] = new JsonObject
            {
                ["version"] = Version(info.VersionQualifier.FirmwareVersion),
                ["type"] = (int)PythonReleaseType(info.VersionQualifier.Type),
                ["iteration"] = info.VersionQualifier.Iteration,
            },
        };
    }

    /// <summary>
    /// The effective firmware version. Like yubikit's read_info, a pre-release key reports the
    /// version from its version qualifier.
    /// </summary>
    public static FirmwareVersion EffectiveVersion(DeviceInfo info) =>
        info.VersionQualifier.Type != VersionQualifierType.Final
            ? info.VersionQualifier.FirmwareVersion
            : info.FirmwareVersion;

    public static JsonArray Version(FirmwareVersion v) => Json.Version(v.Major, v.Minor, v.Patch);

    // yubikit RELEASE_TYPE: ALPHA=0, BETA=1, FINAL=2 (same as the SDK).
    private static VersionQualifierType PythonReleaseType(VersionQualifierType type) => type;

    /// <summary>Port of yubikit.support.get_name for YubiKey 4/5 series and Security Keys over USB.</summary>
    public static string GetName(DeviceInfo info, bool fidoOnlyUsbInterfaces)
    {
        var version = EffectiveVersion(info);
        var usbSupported = info.UsbSupported;
        var isSecurityKeyPlatform = info.SerialNumber is null && IsFidoOnly(usbSupported) && fidoOnlyUsbInterfaces
            && version < new FirmwareVersion(5, 2, 8);
        if (version.Major == 3)
        {
            return "YubiKey NEO";
        }

        if (isSecurityKeyPlatform)
        {
            var name = "Security Key by Yubico";
            if (!usbSupported.HasFlag(DeviceCapabilities.Fido2))
            {
                name = "FIDO U2F Security Key";
            }

            return info.NfcSupported != DeviceCapabilities.None ? "Security Key NFC" : name;
        }

        if (version.Major < 4)
        {
            return version.Major == 0 ? $"YubiKey ({version})" : "YubiKey";
        }

        if (version.Major == 4)
        {
            return info.IsFips ? "YubiKey FIPS (4 Series)"
                : usbSupported == (DeviceCapabilities.Otp | DeviceCapabilities.U2f) ? "YubiKey Edge"
                : "YubiKey 4";
        }

        if (version < new FirmwareVersion(5, 1, 0))
        {
            return "YubiKey Preview";
        }

        var formFactor = info.FormFactor;
        var isNano = formFactor is FormFactor.UsbANano or FormFactor.UsbCNano;
        var isBio = formFactor is FormFactor.UsbABiometricKeychain or FormFactor.UsbCBiometricKeychain;
        var isC = formFactor is FormFactor.UsbCKeychain or FormFactor.UsbCNano or FormFactor.UsbCBiometricKeychain;
        var hasNfc = info.NfcSupported != DeviceCapabilities.None;

        List<string> parts = info.IsSky ? ["Security Key"] : isBio ? ["YubiKey"] : ["YubiKey", "5"];
        if (isC)
        {
            parts.Add("C");
        }
        else if (formFactor == FormFactor.UsbCLightning)
        {
            parts.Add("Ci");
        }

        if (isNano)
        {
            parts.Add("Nano");
        }
        else if (hasNfc)
        {
            parts.Add("NFC");
        }
        else if (formFactor == FormFactor.UsbAKeychain)
        {
            parts.Add("A");
        }
        else if (isBio)
        {
            parts.Add("Bio");
        }

        if (info.IsFips)
        {
            parts.Add("FIPS");
        }
        else if (isBio)
        {
            if (IsFidoOnly(usbSupported))
            {
                parts.Add("- FIDO Edition");
            }
            else if (usbSupported.HasFlag(DeviceCapabilities.Piv))
            {
                parts.Add("- Multi-protocol Edition");
            }
        }
        else if (info.IsSky && info.SerialNumber is not null)
        {
            parts.Add("- Enterprise Edition");
        }
        else if (info.HasPinComplexity && !info.IsSky)
        {
            parts.Add("- Enhanced PIN");
        }

        return string.Join(' ', parts).Replace("5 C", "5C", StringComparison.Ordinal)
            .Replace("5 A", "5A", StringComparison.Ordinal);
    }

    private static bool IsFidoOnly(DeviceCapabilities capabilities) =>
        (capabilities & ~(DeviceCapabilities.U2f | DeviceCapabilities.Fido2)) == DeviceCapabilities.None;
}
