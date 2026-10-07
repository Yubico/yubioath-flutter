# Flutter-to-helper RPC contract and v2 SDK mapping

This documents the contract between the desktop Flutter app (`lib/desktop/`) and the helper
process (`helper/`, Python + yubikey-manager), as of `main` at `b4eca6a3` (app 7.4.x). It's the
contract the .NET helper in `helper-dotnet/` implements. Golden transcripts captured from the
real Python helper live in `helper-dotnet/golden/`.

## 1. Process and transport

| Aspect | Contract | Source |
|---|---|---|
| Launch | The app starts the helper from `_HELPER_PATH`, or `helper/authenticator-helper[.exe]` next to the executable (`../Resources/helper/` on macOS). There are no arguments. | `lib/desktop/init.dart` |
| Requests | One JSON object per line on the helper's stdin. | `lib/desktop/rpc.dart` |
| Responses | One JSON object per line on stdout. | `rpc.dart` |
| Logs | One JSON object per line on stderr: `{time, name, level, message, exc_text?}`. `level` is a Python level name: `TRAFFIC`, `DEBUG`, `INFO`, `WARNING`, `ERROR` or `CRITICAL`. | `rpc.dart` `_logEntry` |
| Shutdown | The app writes an empty line, then closes stdin. | `_RpcConnection.close` |
| Windows elevation | The app relaunches the helper elevated with `--tcp <port> <nonce>`. The helper connects to `127.0.0.1:<port>`, sends the nonce line, then sends every line prefixed with `O` (an RPC response) or `E` (a log record). The app then sends `quit` to the old helper. | `RpcSession.elevate` |
| Concurrency | One command runs at a time. While a command runs, the helper must keep reading stdin, because a `cancel` signal can arrive. | `helper/__init__.py` `process()` |

### Messages

```jsonc
// app -> helper
{"kind": "command", "action": "<name>", "target": ["usb", "125", "ccid", "oath"], "body": {...}}
{"kind": "signal", "status": "cancel"}

// helper -> app
{"kind": "success", "body": {...}, "flags": ["device_info", "device_closed"]}
{"kind": "signal",  "status": "touch" | "reset" | "capture" | "capture-error", "body": {...}}
{"kind": "error",   "status": "<status>", "message": "<text>", "body": {...}}
```

Values are encoded the way Python's `json.dumps` writes them:
- bytes are lowercase hex strings
- IntEnum/IntFlag values are integers
- str enums are strings
- version tuples are `[major, minor, patch]`
- `None` is `null`
- dict keys keyed by `TRANSPORT` are `"usb"` and `"nfc"`.

### The node tree

The helper exposes a tree of nodes (`RpcNode` in `helper/helper/base.py`):
- `target` is a path from the root.
- Each node has actions and children.
- `get` returns `{data, actions, children}`.
- Calling a child's name as an action means `get` on that child. For example, `action: "credentials"` on `[..., "ctap2"]` lists relying parties.

A node keeps at most one child open. Addressing a different child closes the current one. Every action closes the open child unless it's declared `closes_child=False`. This lifecycle is what opens and closes YubiKey connections and sessions, so a compatible helper has to copy it.

```
root                         data: {version, is_admin}; actions: get, logging, qr, diagnose
├── usb                      scan -> {state, pids}; children: {<serial|fingerprint>: {pid, name, serial}}
│   └── <device id>          data: {pid, name, transport, info: DeviceInfo}
│       ├── ccid             (SmartCard connection) data: {version, serial}
│       │   ├── management   data: DeviceInfo; configure, device_reset
│       │   ├── oath         -> accounts -> <credential id hex>
│       │   ├── piv          -> slots -> <slot hex>
│       │   ├── ctap2        (only when FIDO over CCID is enabled, 0x1000 bit)
│       │   └── yubiotp
│       ├── fido             (FIDO HID connection)
│       │   ├── management
│       │   └── ctap2        -> credentials -> <rp id> -> <credential id hex>; fingerprints -> <template id hex>
│       └── otp              (OTP HID connection) management, yubiotp
└── nfc                      scan -> {<reader id>: {name}}; <reader id> -> same subtree as a USB device
```

### Flags

| Flag | Raised by | Effect |
|---|---|---|
| `device_info` | Actions that change device state, for example `set_key`, PIN changes, `generate`, `reset` and `configure`. | The device node re-reads DeviceInfo. **This closes the open application session.** If DeviceInfo is unchanged, the device node removes the flag. If it's still present, the app re-reads the device. |
| `device_closed` | FIDO `reset`, or `configure` with `reboot`. | The device node closes. The devices node forgets its mapping and the app re-enumerates. |

Because the session closes after `device_info`, the PIV management-key authentication, the FIDO PIN token and the OATH unlock are lost after such actions. The app handles this by catching `auth-required` and silently re-authenticating with credentials it keeps in memory.

### Error statuses the app acts on

| status | body | Raised when | App reaction |
|---|---|---|---|
| `auth-required` | `{}` | OATH or PIV gets SW 0x6982, a locked OATH applet's `accounts` is opened, or FIDO `credentials` is used without a token or gets `PIN_AUTH_INVALID`. | Re-authenticate with the cached secret and retry, otherwise prompt. |
| `state-reset` | `{path}` | A child failed with a connection error or SW 0x6D00 (`ChildResetException`). | Invalidate that node's provider and re-read it. |
| `connection-error` | `{device, connection, exc_type}` | A USB interface can't be opened after 3 attempts. | Show the "can't connect" page. |
| `fido-blocked-error` | `{connection}` | Windows, not elevated, FIDO HID access denied. | Offer elevation (`--tcp`). |
| `pin-validation` | `{retries, auth_blocked}` | FIDO wrong PIN, PIN blocked or auth blocked. | Show remaining attempts. |
| `invalid-pin` | `{attempts_remaining}` | PIV wrong PIN or PUK. | Show remaining attempts. |
| `pin-complexity` | `{}` | FIDO `PIN_POLICY_VIOLATION`, or PIV SW 0x6985 on a PIN or PUK change. | Show the weak-PIN error. |
| `user-action-timeout` | `{}` | FIDO reset or fingerprint enrollment timed out. | Show the timeout message. |
| `timeout` | `{}` | OATH or PIV touch not given within about 5 s. | Show `message`. |
| `invalid-command` | `{}` | Unknown action or node, or bad parameters (`ValueError`). | Show `message`. |
| `exception` | `{}` | Anything else. | Show `message`. |

### Signals

| Signal | Body | Sent during |
|---|---|---|
| `touch` | `{}` | OATH `code` and `calculate` on touch credentials (immediately), or HOTP after 0.5 s. PIV `authenticate` with a touch-policy key, and `generate` with a touch policy. |
| `reset` | `{state: "remove" \| "insert" \| "touch" \| "wait"}` | FIDO `reset`: the reinsert sequence, then the touch. |
| `capture` | `{remaining}` | Fingerprint `add`. |
| `capture-error` | `{code}` | Fingerprint `add`. |

## 2. Startup and polling sequence (from golden traffic)

1. `logging {level}` on the root. The level comes from the app's log level.
2. `get []` returns `{version, is_admin}`.
3. Every 500 ms: `scan ["usb"]` returns `{state, pids}`. Only when `state` changes: `get ["usb"]` lists children, then `get ["usb", id]` for each child.
4. Every 2.5 s: `scan ["nfc"]`. Every 1 s: `get ["nfc", reader]` while a reader is selected.
5. When the window loses focus: `get ["usb"]` or `get ["nfc"]`. This closes children, which releases the YubiKey for other applications.
6. Each section page opens its application path:
   - Accounts: `["ccid", "oath"]`
   - Passkeys: `["fido", "ctap2"]`, falling back to `["ccid", "ctap2"]`
   - Certificates: `["ccid", "piv"]`
   - Home and Toggle applications: `["ccid" | "otp" | "fido", "management"]`, first available
   - Slots: `["ccid" | "otp", "yubiotp"]`

## 3. In-scope workflows mapped to the v2 SDK

Status columns:
- **Impl**: implemented in `helper-dotnet`.
- **HW**: exercised on a YubiKey 5 NFC with firmware 5.8.0 alpha (serial 125). "UI" means through the real Authenticator app, "probe" means through `tools/rpc_probe.py` with responses diffed against the Python helper.

### 3.1 Device discovery and management

| RPC | yubikit (Python) | v2 SDK | Impl | HW |
|---|---|---|---|---|
| `scan ["usb"]` | `ykman.device.scan_devices()` (USB enumeration only, no I/O) | `YubiKeyManager.FindAllAsync(ConnectionType.All, forceRescan: true)`. `state` is a hash of `DeviceId` and connections. | yes | UI and probe |
| `get ["usb"]` children | `list_all_devices()`, `get_name()` | `FindAllAsync`, then a Management `GetDeviceInfoAsync` per device. `get_name` is ported in `DeviceInfoJson.GetName`. The PID is rebuilt from `AvailableConnections`. | yes | UI and probe |
| `get ["usb", id]` | `read_info(conn, pid)` | `IYubiKey.ConnectAsync<ISmartCardConnection \| IOtpHidConnection \| IFidoHidConnection>()`, then `ManagementSession.CreateAsync(conn)`, then `GetDeviceInfoAsync()` | yes | UI and probe |
| open `ccid` / `fido` / `otp` | `device.open_connection(type)` | `IYubiKey.ConnectAsync<T>()`, held by `ConnectionNode` | yes | UI and probe |
| `management` `get` | `ManagementSession.read_device_info` | `ManagementSession.GetDeviceInfoAsync` | yes | probe |
| `management` `configure` | `write_device_config` | `ManagementSession.SetDeviceConfigAsync(DeviceConfig, SetDeviceConfigOptions)` | yes | no |
| `management` `device_reset` | `device_reset` | `ManagementSession.ResetDeviceAsync` | yes | no |
| `management` `set_mode` (YubiKey NEO/4) | `set_mode` | not public in v2 (`IManagementBackend.SetModeAsync` is internal) | **no** | no |

### 3.2 FIDO (priority 1)

| RPC | yubikit / python-fido2 | v2 SDK | Impl | HW |
|---|---|---|---|---|
| `ctap2` `get` | `Ctap2.get_info()`, `ClientPin.get_pin_retries()` / `get_uv_retries()` | `FidoSession.CreateAsync(conn)`, `GetInfoAsync()`, `new ClientPin(session, PinUvAuthProtocolV2/V1)`, `GetPinRetriesAsync()`, `GetUvRetriesAsync()` | yes | UI and probe |
| `unlock {pin}` | `ClientPin.get_pin_token(pin, CREDENTIAL_MGMT \| BIO_ENROLL \| AUTHENTICATOR_CFG)` | `ClientPin.GetPinUvAuthTokenUsingPinAsync(pin, PinUvAuthTokenPermissions...)`, or `GetPinTokenAsync` on FIDO 2.0 keys | yes | UI and probe (right and wrong PIN) |
| `unlock {remember: true}` (PPUAT) | `PERSISTENT_CREDENTIAL_MGMT` token in the keychain | `PinUvAuthTokenPermissions.CredentialManagementRO` exists. Persistent storage is out of scope. | **no** | no |
| `set_pin` | `ClientPin.set_pin` / `change_pin` | `ClientPin.SetPinAsync` / `ChangePinAsync` | yes | UI (set after reset) and probe (change, complexity error) |
| `credentials` (list RPs) | `CredentialManagement.get_metadata`, `enumerate_rps` | `new CredentialManagement(session, protocol, token)`, `GetCredentialsMetadataAsync`, `EnumerateRelyingPartiesAsync` | yes | UI (1 passkey) |
| `credentials <rp>` (list creds) | `enumerate_creds(rp_id_hash)` | `EnumerateCredentialsAsync(rpIdHash)` | yes | UI |
| credential `delete` | `delete_cred(descriptor)` | `DeleteCredentialAsync(PublicKeyCredentialDescriptor.FromCredentialId(id))` | yes | UI |
| `reset` with reinsert signals | `device.reinsert()`, `Ctap2.reset(event, on_keepalive)` | Poll `FindAllAsync(forceRescan)` for remove and insert, reconnect, `FidoSession.ResetAsync()`. The touch comes from `IUserPresencePrompt` (`UserPresenceOperations.Fido2.Reset`). | yes | UI (remove, insert, long touch, success) |
| `enable_ep_attestation` | `Config(...).enable_enterprise_attestation` | `new AuthenticatorConfig(session, protocol, token).EnableEnterpriseAttestationAsync()` | yes | no |
| `fingerprints` list, `add`, `rename`, `delete` | `FPBioEnrollment` | `FingerprintBioEnrollment`: `EnumerateEnrollmentsAsync`, `EnrollBeginAsync` / `EnrollCaptureNextSampleAsync`, `SetFriendlyNameAsync`, `RemoveEnrollmentAsync` | yes | no (no Bio key) |
| FIDO over CCID (`["ccid", "ctap2"]`) | `SmartCardCtapDevice` | `FidoSession.CreateAsync(ISmartCardConnection)` | wired | no |

### 3.3 OATH (priority 2)

| RPC | yubikit | v2 SDK | Impl | HW |
|---|---|---|---|---|
| `oath` `get` | `OathSession` properties | `OathSession.CreateAsync(conn, options)`: `DeviceId`, `IsPasswordProtected` (`has_key`), `IsLocked`, `FirmwareVersion` | yes | UI and probe |
| `derive` | `derive_key(password)` | `OathSession.DeriveKey(utf8)` | yes | probe (same key bytes as Python) |
| `validate` | `validate(key)` or a key verifier | `ValidateAsync(key)`, with `OathException(WrongPassword)` mapped to `valid: false`. HMAC verifier for an unlocked session. | yes | probe |
| `set_key`, `unset_key` | `set_key`, `unset_key` | `SetKeyAsync`, `UnsetKeyAsync` | yes | probe |
| `reset` | `reset` | `ResetAsync` | yes | no |
| `accounts` list, `calculate_all` | `calculate_all(timestamp)` | `CalculateAllAsync(timestamp)` | yes | UI (codes checked against RFC 6238) and probe (same code as Python) |
| account `code` | `calculate_code(cred, ts)` | `CalculateCodeAsync(credential, ts)`. Touch comes through `IUserPresencePrompt`, HOTP uses the 0.5 s timer. | yes | probe (TOTP and HOTP) |
| account `calculate` (Steam) | `calculate(id, challenge)` returns the HMAC | `CalculateAsync(credential, challenge)` returns **`[digits][HMAC]`**, so the helper strips byte 0 | yes | probe |
| `put {uri}` / fields | `CredentialData.parse_uri`, `put_credential` | `CredentialData.ParseUri(uri, requireTouch)`, `PutCredentialAsync` | yes | UI (manual entry) and probe |
| account `rename` | `rename_credential` | `RenameCredentialAsync` | yes | probe |
| account `delete` | `delete_credential` | `DeleteCredentialAsync` | yes | UI and probe |
| `validate {remember}`, `forget`, keystore | `AppData("oath_keys")` in the OS keychain | none. Out of scope, so `remembered` is always `false`. | **no** | n/a |

### 3.4 PIV (priority 3)

| RPC | yubikit / ykman.piv | v2 SDK | Impl | HW |
|---|---|---|---|---|
| `piv` `get` | `get_pin/puk/management_key_metadata`, `get_pin_attempts`, `get_bio_metadata`, `get_object(CHUID/CCC)`, `get_pivman_data` | `PivSession.CreateAsync`: `GetPinMetadataAsync`, `GetPukMetadataAsync`, `GetManagementKeyMetadataAsync`, `GetPinAttemptsAsync`, `GetBioMetadataAsync`, `GetObjectAsync(PivDataObject.Chuid/Capability)`, `GetPinOnlyModeAsync` (`derived_key` / `stored_key`) | yes | UI and probe |
| `verify_pin` | `verify_pin`, then authenticate with the pivman derived or stored key | `VerifyPinAsync`, then `RecoverPinOnlyModeAsync(pin)` if PIN-only mode | yes | UI and probe (right and wrong PIN) |
| `authenticate` | `authenticate(key_type, key)` | `AuthenticateAsync(key)` (the type comes from the session) | yes | UI (app auto-auth with default key) and probe |
| `set_key` | `pivman_set_mgm_key(store_on_device)` | `SetManagementKeyAsync(type, key, touch)`. `store_key: true` isn't implemented (`SetPinOnlyModeAsync` exists in the SDK). | partial | no |
| `change_pin`, `change_puk`, `unblock_pin` | `pivman_change_pin`, `change_puk`, `unblock_pin` | `ChangePinAsync`, `ChangePukAsync`, `UnblockPinAsync` (no pivman derived-key update on PIN change) | partial | no |
| `reset` | `reset` | `ResetAsync` | yes | no |
| `slots` list, slot `get` | `get_slot_metadata`, `get_certificate` | `GetSlotMetadataAsync`, `GetCertificateAsync`. SPKI/PEM and `cert_info` are built with `System.Security.Cryptography`. | yes | UI and probe (byte-identical PEM and cert_info) |
| slot `generate` (public key, CSR, self-signed) | `generate_key`, `generate_csr`, `generate_self_signed_certificate`, `generate_chuid` | `GenerateKeyAsync`, `CertificateRequest` with an `X509SignatureGenerator` backed by `SignOrDecryptAsync`, `StoreCertificateAsync`, `SetCardholderUniqueIdAsync(CreateWithRandomGuid())` | yes (RSA and P-256/P-384, no Ed25519 certificates) | UI (P-256 self-signed) and probe (P-256 certificate, RSA-2048 CSR, both verified with openssl) |
| slot `delete` | `delete_certificate`, `delete_key` | `DeleteCertificateAsync`, `DeleteKeyAsync` | yes | UI and probe |
| slot `move_key` | `move_key` | `MoveKeyAsync` | yes | no |
| slot `examine_file`, `import_file` | `parse_certificates`, `parse_private_key`, `put_key` | .NET PEM/DER/PKCS#12 parsing, `RSAPrivateKey/ECPrivateKey.CreateFromPkcs8`, `ImportKeyAsync` | yes (RSA/EC) | `examine_file`: probe. `import_file`: no. |
| `validate_rfc4514` | `parse_rfc4514_string` | `X500DistinguishedName(..., Reversed)` | yes | UI and probe |

### 3.5 Root and out of scope

| RPC | Status |
|---|---|
| `logging` | Implemented. SDK logging (`YubiKitLogging`) is routed to the same stderr JSON format. |
| `qr` | Not implemented (out of scope). The "Scan QR code" button fails; manual entry works. |
| `diagnose` | Not implemented (out of scope). |
| `nfc` readers | `scan` always returns `{}`, so the app shows no readers. Not implemented. |
| `yubiotp` | Not implemented, so the Slots section is unavailable. |
