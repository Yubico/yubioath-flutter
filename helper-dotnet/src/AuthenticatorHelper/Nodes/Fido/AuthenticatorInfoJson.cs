using System.Text;
using System.Text.Json.Nodes;
using Yubico.Authenticator.Helper.Rpc;
using Yubico.YubiKit.Fido2;

namespace Yubico.Authenticator.Helper.Nodes.Fido;

/// <summary>Serializes AuthenticatorInfo like dataclasses.asdict(fido2.ctap2.Info).</summary>
internal static class AuthenticatorInfoJson
{
    public static JsonObject ToJson(AuthenticatorInfo info)
    {
        var options = new JsonObject();
        foreach (var (key, value) in info.Options)
        {
            options[key] = value;
        }

        var algorithms = new JsonArray();
        foreach (var algorithm in info.Algorithms)
        {
            algorithms.Add((JsonNode)new JsonObject { ["alg"] = (int)algorithm.Algorithm, ["type"] = algorithm.Type });
        }

        var certifications = new JsonObject();
        foreach (var (key, value) in info.Certifications)
        {
            certifications[key] = value;
        }

        return new JsonObject
        {
            ["versions"] = Json.Array(info.Versions),
            ["extensions"] = Json.Array(info.Extensions),
            ["aaguid"] = Json.Hex(info.Aaguid.Span),
            ["options"] = options,
            ["max_msg_size"] = info.MaxMsgSize ?? 1024,
            ["pin_uv_protocols"] = Json.Array(info.PinUvAuthProtocols),
            ["max_creds_in_list"] = info.MaxCredentialCountInList,
            ["max_cred_id_length"] = info.MaxCredentialIdLength,
            ["transports"] = Json.Array(info.Transports),
            ["algorithms"] = algorithms,
            ["max_large_blob"] = info.MaxSerializedLargeBlobArray,
            ["force_pin_change"] = info.ForcePinChange ?? false,
            ["min_pin_length"] = info.MinPinLength ?? 4,
            ["firmware_version"] = info.FirmwareVersion is { } fw ? (fw.Major << 16) | (fw.Minor << 8) | fw.Patch : null,
            ["max_cred_blob_length"] = info.MaxCredBlobLength,
            ["max_rpids_for_min_pin"] = info.MaxRpidsForSetMinPinLength ?? 0,
            ["preferred_platform_uv_attempts"] = info.PreferredPlatformUvAttempts ?? 0,
            ["uv_modality"] = info.UvModality ?? 0,
            ["certifications"] = certifications,
            ["remaining_disc_creds"] = info.RemainingDiscoverableCredentials,
            ["vendor_prototype_config_commands"] = Json.Array(info.VendorPrototypeConfigCommands),
            ["attestation_formats"] = Json.Array(info.AttestationFormats),
            ["uv_count_since_pin"] = info.UvCountSinceLastPinEntry,
            ["long_touch_for_reset"] = info.LongTouchForReset,
            ["enc_identifier"] = Json.HexOrNull(info.EncIdentifier),
            ["transports_for_reset"] = Json.Array(info.TransportsForReset),
            ["pin_complexity_policy"] = info.PinComplexityPolicy,
            ["pin_complexity_policy_url"] = info.PinComplexityPolicyUrl is { } url
                ? Json.Hex(Encoding.UTF8.GetBytes(url))
                : null,
            ["max_pin_length"] = info.MaxPinLength ?? 63,
            ["enc_cred_store_state"] = Json.HexOrNull(info.EncCredStoreState),
            ["authenticator_config_commands"] = info.AuthenticatorConfigCommands.Count == 0
                ? null
                : Json.Array(info.AuthenticatorConfigCommands),
        };
    }
}
