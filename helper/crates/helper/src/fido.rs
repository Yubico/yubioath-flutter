use std::collections::BTreeMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use serde_json::{Value, json};

use yubikit::cbor::Value as CborValue;
use yubikit::core::Transport;
use yubikit::ctap::CtapSession;
use yubikit::ctap2::{
    BioEnrollment, ClientPin, Config, CredentialManagement, Ctap2Error, Ctap2Pin, Ctap2Session,
    CtapStatus, Info, Permissions, PinProtocol, PublicKeyCredentialDescriptor,
};
use yubikit::device::{ReinsertStatus, YubiKeyDevice};
use yubikit::fido::FidoConnection;
use yubikit::smartcard::SmartCardConnection;

use crate::appdata::AppData;
use crate::connection::SharedConn;
use crate::error::{RpcError, RpcResponse, SecretStore};
use crate::rpc::{RpcNode, SignalFn};

use std::sync::Mutex as StdMutex;

/// Result of an unlock operation: (token, protocol, optional (ppuat, ident)).
type UnlockResult = Result<(Vec<u8>, PinProtocol, Option<(Vec<u8>, Vec<u8>)>), RpcError>;

// --- PPUAT (Persistent PIN/UV Auth Token) store ---

static PPUAT_STATE: std::sync::LazyLock<StdMutex<PpuatStore>> =
    std::sync::LazyLock::new(|| StdMutex::new(PpuatStore::new()));

struct PpuatStore {
    keystore_state: SecretStore,
    ppuats: AppData,
}

impl PpuatStore {
    fn new() -> Self {
        Self {
            keystore_state: SecretStore::Unknown,
            ppuats: AppData::new("ppuats"),
        }
    }

    fn ensure_unlocked(&mut self) -> bool {
        if self.keystore_state == SecretStore::Unknown {
            match self.ppuats.ensure_unlocked() {
                Ok(()) => self.keystore_state = SecretStore::Allowed,
                Err(e) => {
                    log::warn!("Couldn't read key from Keychain: {e}");
                    self.keystore_state = SecretStore::Failed;
                }
            }
        }
        self.keystore_state == SecretStore::Allowed
    }
}

// --- CTAP error → RPC error mapping ---

/// Select the preferred PIN protocol from device info (V2 > V1).
fn select_pin_protocol(info: &Info) -> Option<PinProtocol> {
    for &version in &[2u32, 1] {
        if info.pin_uv_protocols.contains(&version) {
            return Some(match version {
                2 => PinProtocol::V2,
                _ => PinProtocol::V1,
            });
        }
    }
    None
}

fn handle_pin_error<E: std::error::Error + Send + Sync + 'static>(
    e: &Ctap2Error<E>,
    retries: u32,
) -> RpcError {
    if let Ctap2Error::StatusError(status) = e {
        match status {
            CtapStatus::PinInvalid | CtapStatus::PinBlocked | CtapStatus::PinAuthBlocked => {
                return RpcError::with_body(
                    "pin-validation",
                    "Authentication is required",
                    json!({
                        "retries": retries,
                        "auth_blocked": *status == CtapStatus::PinAuthBlocked,
                    }),
                );
            }
            CtapStatus::PinPolicyViolation => {
                return RpcError::pin_complexity();
            }
            CtapStatus::UserActionTimeout => {
                return RpcError::timeout();
            }
            CtapStatus::PinAuthInvalid => {
                return RpcError::auth_required();
            }
            _ => {}
        }
    }
    RpcError::new("device-error", format!("{e}"))
}

fn cbor_to_json(v: &CborValue) -> Value {
    match v {
        CborValue::Int(n) => json!(*n),
        CborValue::Text(s) => json!(s),
        CborValue::Bool(b) => json!(*b),
        CborValue::Bytes(b) => json!(hex::encode(b)),
        CborValue::Array(arr) => Value::Array(arr.iter().map(cbor_to_json).collect()),
        CborValue::Map(pairs) => {
            let mut map = serde_json::Map::new();
            for (k, v) in pairs {
                let key = match k {
                    CborValue::Text(s) => s.clone(),
                    CborValue::Int(n) => n.to_string(),
                    _ => format!("{k:?}"),
                };
                map.insert(key, cbor_to_json(v));
            }
            Value::Object(map)
        }
    }
}

fn info_to_json(info: &Info) -> Value {
    let algorithms: Vec<Value> = info
        .algorithms
        .iter()
        .map(|alg| {
            json!({
                "type": alg.type_,
                "alg": alg.alg,
            })
        })
        .collect();

    let certifications: serde_json::Map<String, Value> = info
        .certifications
        .iter()
        .map(|(k, v)| (k.clone(), cbor_to_json(v)))
        .collect();

    json!({
        "versions": info.versions,
        "extensions": info.extensions,
        "aaguid": hex::encode(info.aaguid.as_bytes()),
        "options": info.options,
        "max_msg_size": info.max_msg_size,
        "pin_uv_protocols": info.pin_uv_protocols,
        "max_creds_in_list": info.max_creds_in_list,
        "max_cred_id_length": info.max_cred_id_length,
        "transports": info.transports,
        "algorithms": algorithms,
        "max_large_blob": info.max_large_blob,
        "force_pin_change": info.force_pin_change,
        "min_pin_length": info.min_pin_length,
        "firmware_version": info.firmware_version,
        "max_cred_blob_length": info.max_cred_blob_length,
        "max_rpids_for_min_pin": info.max_rpids_for_min_pin,
        "preferred_platform_uv_attempts": info.preferred_platform_uv_attempts,
        "uv_modality": info.uv_modality,
        "certifications": certifications,
        "remaining_disc_creds": info.remaining_disc_creds,
        "vendor_prototype_config_commands": info.vendor_prototype_config_commands,
        "attestation_formats": info.attestation_formats,
        "uv_count_since_pin": info.uv_count_since_pin,
        "long_touch_for_reset": info.long_touch_for_reset,
        "transports_for_reset": info.transports_for_reset,
    })
}

// --- Transport-generic dispatch macros ---
//
// These macros create a CtapSession + Ctap2Session from a connection enum,
// run the body, and put the raw connection back.
//
// The body receives a `Ctap2Session<C>` and must return `(Result<R, RpcError>, C)`
// where `C` is the recovered raw connection (via `.into_session().into_connection()`).

macro_rules! with_ctap2 {
    ($fido_conn:expr, |$session:ident| $body:expr) => {
        match $fido_conn {
            FidoConn::Hid { conn, .. } => match conn.take() {
                None => Err(RpcError::new("connection-error", "Connection in use")),
                Some(c) => match CtapSession::new_fido(c) {
                    Err((e, c)) => {
                        *conn = Some(c);
                        Err(RpcError::new("device-error", format!("{e}")))
                    }
                    Ok(ctap) => match Ctap2Session::new(ctap) {
                        Err((e, _)) => Err(RpcError::new("device-error", format!("{e}"))),
                        Ok($session) => {
                            let (result, returned_c) = { $body };
                            *conn = Some(returned_c);
                            result
                        }
                    },
                },
            },
            FidoConn::SmartCard { conn, .. } => match conn.take() {
                None => Err(RpcError::new("connection-error", "Connection in use")),
                Some(c) => match CtapSession::new(c) {
                    Err((e, c)) => {
                        *conn = Some(c);
                        Err(RpcError::new("device-error", format!("{e}")))
                    }
                    Ok(ctap) => match Ctap2Session::new(ctap) {
                        Err((e, _)) => Err(RpcError::new("device-error", format!("{e}"))),
                        Ok($session) => {
                            let (result, returned_c) = { $body };
                            *conn = Some(returned_c);
                            result
                        }
                    },
                },
            },
        }
    };
}

/// Same as `with_ctap2!` but for `FidoDeviceType`, also tries the shared connection.
macro_rules! with_ctap2_dev {
    ($device_type:expr, |$session:ident| $body:expr) => {
        match $device_type {
            FidoDeviceType::Hid { conn, shared } => {
                match conn.take().or_else(|| shared.lock().unwrap().take()) {
                    None => Err(RpcError::new("connection-error", "Connection in use")),
                    Some(c) => match CtapSession::new_fido(c) {
                        Err((e, c)) => {
                            *conn = Some(c);
                            Err(RpcError::new("device-error", format!("{e}")))
                        }
                        Ok(ctap) => match Ctap2Session::new(ctap) {
                            Err((e, _)) => Err(RpcError::new("device-error", format!("{e}"))),
                            #[allow(unused_mut)]
                            Ok(mut $session) => {
                                let (result, returned_c) = { $body };
                                *conn = Some(returned_c);
                                result
                            }
                        },
                    },
                }
            }
            FidoDeviceType::SmartCard { conn, shared } => {
                match conn.take().or_else(|| shared.lock().unwrap().take()) {
                    None => Err(RpcError::new("connection-error", "Connection in use")),
                    Some(c) => match CtapSession::new(c) {
                        Err((e, c)) => {
                            *conn = Some(c);
                            Err(RpcError::new("device-error", format!("{e}")))
                        }
                        Ok(ctap) => match Ctap2Session::new(ctap) {
                            Err((e, _)) => Err(RpcError::new("device-error", format!("{e}"))),
                            #[allow(unused_mut)]
                            Ok(mut $session) => {
                                let (result, returned_c) = { $body };
                                *conn = Some(returned_c);
                                result
                            }
                        },
                    },
                }
            }
        }
    };
}

// --- Ctap2Node ---

pub struct Ctap2Node {
    device_type: FidoDeviceType,
    device: Option<Box<dyn YubiKeyDevice>>,
    transport: Transport,
    pin_token: Option<Vec<u8>>,
    pin_protocol: Option<PinProtocol>,
    ppuat: Option<Vec<u8>>,
    ident: Option<Vec<u8>>,
    cached_data: Value,
}

enum FidoDeviceType {
    Hid {
        conn: Option<Box<dyn FidoConnection + Send>>,
        shared: SharedConn<Box<dyn FidoConnection + Send>>,
    },
    SmartCard {
        conn: Option<Box<dyn SmartCardConnection + Send>>,
        shared: SharedConn<Box<dyn SmartCardConnection + Send>>,
    },
}

impl Ctap2Node {
    pub fn new_hid(
        conn: Box<dyn FidoConnection + Send>,
        shared: SharedConn<Box<dyn FidoConnection + Send>>,
        device: Option<Box<dyn YubiKeyDevice>>,
    ) -> Result<Self, RpcError> {
        let mut node = Self {
            device_type: FidoDeviceType::Hid {
                conn: Some(conn),
                shared,
            },
            device,
            transport: Transport::Usb,
            pin_token: None,
            pin_protocol: None,
            ppuat: None,
            ident: None,
            cached_data: json!({}),
        };
        node.refresh_data();
        Ok(node)
    }

    pub fn new_smartcard(
        conn: Box<dyn SmartCardConnection + Send>,
        shared: SharedConn<Box<dyn SmartCardConnection + Send>>,
        device: Option<Box<dyn YubiKeyDevice>>,
    ) -> Result<Self, RpcError> {
        let transport = device
            .as_ref()
            .map(|d| d.transport())
            .unwrap_or(Transport::Usb);
        let mut node = Self {
            device_type: FidoDeviceType::SmartCard {
                conn: Some(conn),
                shared,
            },
            device,
            transport,
            pin_token: None,
            pin_protocol: None,
            ppuat: None,
            ident: None,
            cached_data: json!({}),
        };
        node.refresh_data();
        Ok(node)
    }

    /// Try to find a stored PPUAT that matches this device.
    fn load_ppuat(&mut self, info: &Info) {
        if !CredentialManagement::<Box<dyn FidoConnection + Send>>::is_readonly_supported(info) {
            return;
        }

        let mut store = PPUAT_STATE.lock().unwrap();
        if store.ppuats.keys().next().is_none() || !store.ensure_unlocked() {
            return;
        }

        let keys: Vec<String> = store.ppuats.keys().cloned().collect();
        for ident_hex in &keys {
            match store.ppuats.get_secret(ident_hex) {
                Ok(ppuat_hex) => {
                    if let Ok(ppuat_bytes) = hex::decode(&ppuat_hex)
                        && let Some(curr_ident) = info.get_identifier(&ppuat_bytes)
                        && let Ok(stored_ident) = hex::decode(ident_hex)
                        && stored_ident == curr_ident
                    {
                        log::debug!("Using stored PPUAT");
                        self.ppuat = Some(ppuat_bytes);
                        self.ident = Some(curr_ident);
                        if self.pin_protocol.is_none() {
                            self.pin_protocol = select_pin_protocol(info);
                        }
                        return;
                    }
                }
                Err(e) => {
                    log::warn!("Failed to unwrap access key: {e}");
                }
            }
        }
    }

    /// Delete the stored PPUAT for the current device.
    fn delete_ppuat(&mut self) {
        if self.ppuat.is_none() {
            return;
        }
        if let Some(ident) = &self.ident {
            log::debug!("Deleting stored PPUAT");
            let mut store = PPUAT_STATE.lock().unwrap();
            let _ = store.ppuats.remove(&hex::encode(ident));
            let _ = store.ppuats.write();
        }
        self.ppuat = None;
        self.ident = None;
    }

    fn refresh_data(&mut self) {
        let data: Result<(Value, Info), RpcError> =
            with_ctap2_dev!(&mut self.device_type, |ctap2| {
                match ctap2.get_info() {
                    Err(e) => {
                        let conn = ctap2.into_session().into_connection();
                        (Err(RpcError::new("device-error", format!("{e}"))), conn)
                    }
                    Ok(info) => {
                        let mut data = json!({
                            "info": info_to_json(&info),
                        });

                        let needs_pin = info.options.get("clientPin") == Some(&true);
                        let has_bio = info.options.get("bioEnroll") == Some(&true);

                        if needs_pin {
                            match ClientPin::new(ctap2) {
                                Err((e, s)) => {
                                    let conn = s.into_session().into_connection();
                                    (Err(RpcError::new("device-error", format!("{e}"))), conn)
                                }
                                Ok(mut client_pin) => {
                                    let (pin_retries, power_cycle) =
                                        client_pin.get_pin_retries().unwrap_or((0, None));
                                    data["pin_retries"] = json!(pin_retries);
                                    data["power_cycle"] = json!(power_cycle);

                                    if has_bio {
                                        let uv_retries = client_pin.get_uv_retries().unwrap_or(0);
                                        data["uv_retries"] = json!(uv_retries);
                                    }
                                    let conn =
                                        client_pin.into_session().into_session().into_connection();
                                    (Ok((data, info)), conn)
                                }
                            }
                        } else {
                            let conn = ctap2.into_session().into_connection();
                            (Ok((data, info)), conn)
                        }
                    }
                }
            });
        if let Ok((d, info)) = data {
            self.cached_data = d;
            // Try to load a stored PPUAT on first refresh (construction).
            if self.ppuat.is_none() {
                self.load_ppuat(&info);
            }
        }
    }

    fn do_reset(&mut self, signal: SignalFn, cancel: &AtomicBool) -> Result<RpcResponse, RpcError> {
        // Drop existing connection
        match &mut self.device_type {
            FidoDeviceType::Hid { conn, .. } => {
                let _ = conn.take();
            }
            FidoDeviceType::SmartCard { conn, .. } => {
                let _ = conn.take();
            }
        }

        let device = self
            .device
            .as_mut()
            .ok_or_else(|| RpcError::new("device-error", "No device available for reset"))?;

        device
            .reinsert(
                &|status| match status {
                    ReinsertStatus::Remove => {
                        signal("reset", json!({"state": "remove"}));
                    }
                    ReinsertStatus::Reinsert => {
                        signal("reset", json!({"state": "insert"}));
                    }
                },
                &|| cancel.load(Ordering::Relaxed),
            )
            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

        let is_cancelled = || cancel.load(Ordering::Relaxed);

        // Re-open connection and perform reset based on type
        match &mut self.device_type {
            FidoDeviceType::Hid { conn, .. } => {
                let new_conn = device
                    .open_fido()
                    .map_err(|e| RpcError::new("connection-error", format!("{e}")))?;
                let ctap = CtapSession::new_fido(new_conn)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;
                let mut ctap2 = Ctap2Session::new(ctap)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;

                signal("reset", json!({"state": "touch"}));
                let result = ctap2
                    .reset(Some(&mut |_| {}), Some(&is_cancelled))
                    .map_err(|e| {
                        if matches!(&e, Ctap2Error::StatusError(CtapStatus::UserActionTimeout)) {
                            return RpcError::timeout();
                        }
                        RpcError::new("device-error", format!("{e}"))
                    });

                *conn = Some(ctap2.into_session().into_connection());
                result?;
            }
            FidoDeviceType::SmartCard { conn, .. } => {
                let new_conn = device
                    .open_smartcard()
                    .map_err(|e| RpcError::new("connection-error", format!("{e}")))?;
                let ctap = CtapSession::new(new_conn)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;
                let mut ctap2 = Ctap2Session::new(ctap)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;

                signal("reset", json!({"state": "touch"}));
                let result = ctap2
                    .reset(Some(&mut |_| {}), Some(&is_cancelled))
                    .map_err(|e| {
                        if matches!(&e, Ctap2Error::StatusError(CtapStatus::UserActionTimeout)) {
                            return RpcError::timeout();
                        }
                        RpcError::new("device-error", format!("{e}"))
                    });

                *conn = Some(ctap2.into_session().into_connection());
                result?;
            }
        }

        self.pin_token = None;
        self.delete_ppuat();
        Ok(RpcResponse::with_flags(
            json!({}),
            vec!["device_info", "device_closed"],
        ))
    }

    fn can_reset(&self) -> bool {
        let transports_for_reset = self
            .cached_data
            .get("info")
            .and_then(|i| i.get("transports_for_reset"))
            .and_then(|v| v.as_array());
        match transports_for_reset.map(|v| v.as_slice()) {
            None | Some([]) => true,
            Some(transports) => {
                let current = match self.transport {
                    Transport::Usb => "usb",
                    Transport::Nfc => "nfc",
                };
                transports.iter().any(|t| t.as_str() == Some(current))
            }
        }
    }
}

impl RpcNode for Ctap2Node {
    fn get_data(&self) -> Value {
        let mut data = self.cached_data.clone();
        let has_token = self.pin_token.is_some();
        data["unlocked_read"] = json!(has_token || self.ppuat.is_some());
        data["unlocked"] = json!(has_token);
        data
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = Vec::new();
        if self.can_reset() {
            actions.push("reset");
        }
        let options = self.cached_data.get("info").and_then(|i| i.get("options"));
        if options.and_then(|o| o.get("clientPin")) == Some(&json!(true)) {
            actions.push("unlock");
        }
        actions.push("set_pin");
        if options.and_then(|o| o.get("authnrCfg")) == Some(&json!(true)) {
            actions.push("enable_ep_attestation");
        }
        actions
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();

        let options = self.cached_data.get("info").and_then(|i| i.get("options"));
        let has_cred_mgmt = options
            .and_then(|o| o.get("credMgmt").or_else(|| o.get("credentialMgmtPreview")))
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        if has_cred_mgmt {
            children.insert("credentials".to_string(), json!({}));
        }

        let has_bio = options
            .map(|o| o.get("bioEnroll").is_some())
            .unwrap_or(false);
        if has_bio {
            children.insert("fingerprints".to_string(), json!({}));
        }

        children
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let result = self.do_call_action(action, params, signal, cancel);
        // If we get an auth error and no regular token was used, the PPUAT
        // may have been invalid — delete it so we don't keep trying.
        if let Err(ref e) = result
            && e.status == "auth-required"
            && self.pin_token.is_none()
        {
            self.delete_ppuat();
        }
        result
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let result = self.do_create_child(name);
        if let Err(ref e) = result
            && e.status == "auth-required"
            && self.pin_token.is_none()
        {
            self.delete_ppuat();
        }
        result
    }

    fn close(&mut self) {
        match &mut self.device_type {
            FidoDeviceType::Hid { conn, shared } => {
                if let Some(c) = conn.take() {
                    *shared.lock().unwrap() = Some(c);
                }
            }
            FidoDeviceType::SmartCard { conn, shared } => {
                if let Some(c) = conn.take() {
                    *shared.lock().unwrap() = Some(c);
                }
            }
        }
    }
}

impl Ctap2Node {
    fn do_call_action(
        &mut self,
        action: &str,
        params: Value,
        signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "unlock" => {
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing pin"))?
                    .to_string();
                let remember = params
                    .get("remember")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let result: UnlockResult = with_ctap2_dev!(&mut self.device_type, |ctap2| {
                    match ctap2.get_info() {
                        Err(e) => {
                            let conn = ctap2.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(info) => {
                            let mut permissions = Permissions::new(0);
                            let options = &info.options;
                            if options.get("credMgmt") == Some(&true)
                                || options.get("credentialMgmtPreview") == Some(&true)
                            {
                                permissions |= Permissions::CREDENTIAL_MGMT;
                            }
                            if options.contains_key("bioEnroll")
                                || options.contains_key("userVerificationMgmtPreview")
                            {
                                permissions |= Permissions::BIO_ENROLL;
                            }
                            if options.get("authnrCfg") == Some(&true) {
                                permissions |= Permissions::AUTHENTICATOR_CFG;
                            }

                            let supports_readonly = CredentialManagement::<
                                Box<dyn FidoConnection + Send>,
                            >::is_readonly_supported(
                                &info
                            );

                            let perms = if permissions.bits() > 0 {
                                Some(permissions)
                            } else {
                                Some(Permissions::GET_ASSERTION)
                            };
                            let rpid = if permissions.bits() == 0 {
                                Some("ykman.example.com")
                            } else {
                                None
                            };

                            match ClientPin::new(ctap2) {
                                Err((e, s)) => {
                                    let conn = s.into_session().into_connection();
                                    (Err(RpcError::new("device-error", format!("{e}"))), conn)
                                }
                                Ok(mut client_pin) => {
                                    // If remember requested, get a persistent PPUAT first
                                    let ppuat_data =
                                        if remember && self.ppuat.is_none() && supports_readonly {
                                            let ctap2_pin = Ctap2Pin::new(&pin).map_err(|e| {
                                                RpcError::invalid_params(e.to_string())
                                            })?;
                                            match client_pin.get_pin_token(
                                                &ctap2_pin,
                                                Some(Permissions::PERSISTENT_CREDENTIAL_MGMT),
                                                None,
                                            ) {
                                                Ok(ppuat) => {
                                                    let ident = info.get_identifier(&ppuat);
                                                    ident.map(|id| (ppuat, id))
                                                }
                                                Err(_) => None,
                                            }
                                        } else {
                                            None
                                        };

                                    // Get the regular token
                                    let ctap2_pin = Ctap2Pin::new(&pin)
                                        .map_err(|e| RpcError::invalid_params(e.to_string()))?;
                                    match client_pin.get_pin_token(&ctap2_pin, perms, rpid) {
                                        Ok(token) => {
                                            let protocol = client_pin.protocol();
                                            let conn = client_pin
                                                .into_session()
                                                .into_session()
                                                .into_connection();
                                            (Ok((token, protocol, ppuat_data)), conn)
                                        }
                                        Err(e) => {
                                            let retries =
                                                client_pin.get_pin_retries().unwrap_or((0, None)).0;
                                            let conn = client_pin
                                                .into_session()
                                                .into_session()
                                                .into_connection();
                                            (Err(handle_pin_error(&e, retries)), conn)
                                        }
                                    }
                                }
                            }
                        }
                    }
                });
                result.map(|(token, protocol, ppuat_data)| {
                    self.pin_token = Some(token);
                    self.pin_protocol = Some(protocol);

                    // Store the PPUAT if we got one
                    if let Some((ppuat, ident)) = ppuat_data {
                        let mut store = PPUAT_STATE.lock().unwrap();
                        if store.ensure_unlocked() {
                            let _ = store
                                .ppuats
                                .put_secret(&hex::encode(&ident), &hex::encode(&ppuat));
                            let _ = store.ppuats.write();
                        }
                        self.ppuat = Some(ppuat);
                        self.ident = Some(ident);
                    }

                    RpcResponse::new(json!({}))
                })
            }
            "set_pin" => {
                let new_pin = params
                    .get("new_pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing new_pin"))?
                    .to_string();
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());

                with_ctap2_dev!(&mut self.device_type, |ctap2| {
                    match ctap2.get_info() {
                        Err(e) => {
                            let conn = ctap2.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(info) => {
                            let has_pin = info.options.get("clientPin") == Some(&true);
                            match ClientPin::new(ctap2) {
                                Err((e, s)) => {
                                    let conn = s.into_session().into_connection();
                                    (Err(RpcError::new("device-error", format!("{e}"))), conn)
                                }
                                Ok(mut client_pin) => {
                                    if has_pin && pin.is_none() {
                                        let conn = client_pin
                                            .into_session()
                                            .into_session()
                                            .into_connection();
                                        (Err(RpcError::invalid_params("Missing pin")), conn)
                                    } else {
                                        let result = if has_pin {
                                            let old_pin =
                                                Ctap2Pin::new(pin.as_deref().unwrap()).unwrap();
                                            let new_p = Ctap2Pin::new(&new_pin).unwrap();
                                            client_pin.change_pin(&old_pin, &new_p)
                                        } else {
                                            let new_p = Ctap2Pin::new(&new_pin).unwrap();
                                            client_pin.set_pin(&new_p)
                                        };

                                        match result {
                                            Ok(()) => {
                                                let conn = client_pin
                                                    .into_session()
                                                    .into_session()
                                                    .into_connection();
                                                (Ok(()), conn)
                                            }
                                            Err(e) => {
                                                let retries = client_pin
                                                    .get_pin_retries()
                                                    .unwrap_or((0, None))
                                                    .0;
                                                let conn = client_pin
                                                    .into_session()
                                                    .into_session()
                                                    .into_connection();
                                                (Err(handle_pin_error(&e, retries)), conn)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })?;
                self.pin_token = None;
                self.delete_ppuat();
                self.refresh_data();
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "enable_ep_attestation" => {
                let has_pin = self
                    .cached_data
                    .get("info")
                    .and_then(|i| i.get("options"))
                    .and_then(|o| o.get("clientPin"))
                    == Some(&json!(true));
                if has_pin && self.pin_token.is_none() {
                    return Err(RpcError::auth_required());
                }
                let token = self.pin_token.clone();
                let protocol = self.pin_protocol;
                with_ctap2_dev!(&mut self.device_type, |session| {
                    let config_result = if let (Some(token), Some(protocol)) = (token, protocol) {
                        Config::new(session, protocol, token)
                    } else {
                        Config::new_unauthenticated(session)
                    };
                    match config_result {
                        Err((e, s)) => {
                            let conn = s.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(mut config) => {
                            let result = config
                                .enable_enterprise_attestation()
                                .map_err(|e| RpcError::new("device-error", format!("{e}")));
                            let conn = config.into_session().into_session().into_connection();
                            (result, conn)
                        }
                    }
                })?;
                Ok(RpcResponse::new(json!({})))
            }
            "reset" => {
                if !self.can_reset() {
                    return Err(RpcError::new(
                        "not-supported",
                        "Reset not allowed on this transport",
                    ));
                }
                self.do_reset(signal, cancel)
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn do_create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        match name {
            "credentials" => {
                // Prioritize normal token over PPUAT
                let token = self
                    .pin_token
                    .as_ref()
                    .or(self.ppuat.as_ref())
                    .ok_or_else(RpcError::auth_required)?
                    .clone();
                let protocol = self.pin_protocol.ok_or_else(RpcError::auth_required)?;

                match &mut self.device_type {
                    FidoDeviceType::Hid { conn, shared } => {
                        let c = conn
                            .take()
                            .or_else(|| shared.lock().unwrap().take())
                            .ok_or_else(|| {
                                RpcError::new("connection-error", "Connection in use")
                            })?;
                        Ok(Box::new(CredentialsRpsNode::new_hid(
                            c,
                            shared.clone(),
                            token,
                            protocol,
                        )?))
                    }
                    FidoDeviceType::SmartCard { conn, shared } => {
                        let c = conn
                            .take()
                            .or_else(|| shared.lock().unwrap().take())
                            .ok_or_else(|| {
                                RpcError::new("connection-error", "Connection in use")
                            })?;
                        Ok(Box::new(CredentialsRpsNode::new_smartcard(
                            c,
                            shared.clone(),
                            token,
                            protocol,
                        )?))
                    }
                }
            }
            "fingerprints" => {
                let token = self
                    .pin_token
                    .as_ref()
                    .ok_or_else(RpcError::auth_required)?
                    .clone();
                let protocol = self.pin_protocol.ok_or_else(RpcError::auth_required)?;

                match &mut self.device_type {
                    FidoDeviceType::Hid { conn, shared } => {
                        let c = conn
                            .take()
                            .or_else(|| shared.lock().unwrap().take())
                            .ok_or_else(|| {
                                RpcError::new("connection-error", "Connection in use")
                            })?;
                        Ok(Box::new(FingerprintsNode::new_hid(
                            c,
                            shared.clone(),
                            token,
                            protocol,
                        )?))
                    }
                    FidoDeviceType::SmartCard { conn, shared } => {
                        let c = conn
                            .take()
                            .or_else(|| shared.lock().unwrap().take())
                            .ok_or_else(|| {
                                RpcError::new("connection-error", "Connection in use")
                            })?;
                        Ok(Box::new(FingerprintsNode::new_smartcard(
                            c,
                            shared.clone(),
                            token,
                            protocol,
                        )?))
                    }
                }
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }
}

// --- FidoConn ---

enum FidoConn {
    Hid {
        conn: Option<Box<dyn FidoConnection + Send>>,
        shared: SharedConn<Box<dyn FidoConnection + Send>>,
    },
    SmartCard {
        conn: Option<Box<dyn SmartCardConnection + Send>>,
        shared: SharedConn<Box<dyn SmartCardConnection + Send>>,
    },
}

impl FidoConn {
    fn close(&mut self) {
        match self {
            FidoConn::Hid { conn, shared } => {
                if let Some(c) = conn.take() {
                    *shared.lock().unwrap() = Some(c);
                }
            }
            FidoConn::SmartCard { conn, shared } => {
                if let Some(c) = conn.take() {
                    *shared.lock().unwrap() = Some(c);
                }
            }
        }
    }
}

impl Drop for FidoConn {
    fn drop(&mut self) {
        self.close();
    }
}

// --- CredentialsRpsNode ---

struct CredentialsRpsNode {
    fido_conn: FidoConn,
    token: Vec<u8>,
    protocol: PinProtocol,
    rps: BTreeMap<String, Value>,
    rp_hashes: BTreeMap<String, Vec<u8>>,
}

impl CredentialsRpsNode {
    fn new_hid(
        conn: Box<dyn FidoConnection + Send>,
        shared: SharedConn<Box<dyn FidoConnection + Send>>,
        token: Vec<u8>,
        protocol: PinProtocol,
    ) -> Result<Self, RpcError> {
        let mut node = Self {
            fido_conn: FidoConn::Hid {
                conn: Some(conn),
                shared,
            },
            token,
            protocol,
            rps: BTreeMap::new(),
            rp_hashes: BTreeMap::new(),
        };
        node.refresh()?;
        Ok(node)
    }

    fn new_smartcard(
        conn: Box<dyn SmartCardConnection + Send>,
        shared: SharedConn<Box<dyn SmartCardConnection + Send>>,
        token: Vec<u8>,
        protocol: PinProtocol,
    ) -> Result<Self, RpcError> {
        let mut node = Self {
            fido_conn: FidoConn::SmartCard {
                conn: Some(conn),
                shared,
            },
            token,
            protocol,
            rps: BTreeMap::new(),
            rp_hashes: BTreeMap::new(),
        };
        node.refresh()?;
        Ok(node)
    }

    fn refresh(&mut self) -> Result<(), RpcError> {
        self.rps.clear();
        self.rp_hashes.clear();

        let token = self.token.clone();
        let protocol = self.protocol;

        let (rp_map, hash_map): (BTreeMap<String, Value>, BTreeMap<String, Vec<u8>>) =
            with_ctap2!(&mut self.fido_conn, |ctap2| {
                match CredentialManagement::new(ctap2, protocol, token) {
                    Err((e, s)) => {
                        let conn = s.into_session().into_connection();
                        (Err(RpcError::new("device-error", format!("{e}"))), conn)
                    }
                    Ok(mut credman) => {
                        let result = (|| -> Result<_, RpcError> {
                            let (existing, _) = credman
                                .get_metadata()
                                .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                            if existing == 0 {
                                return Ok((BTreeMap::new(), BTreeMap::new()));
                            }

                            let rps = credman
                                .enumerate_rps()
                                .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                            let mut rp_map = BTreeMap::new();
                            let mut hash_map = BTreeMap::new();
                            for rp_info in &rps {
                                let rp_id = &rp_info.rp.id;
                                rp_map.insert(rp_id.clone(), json!({"rp_id": rp_id}));
                                hash_map.insert(rp_id.clone(), rp_info.rp_id_hash.clone());
                            }
                            Ok((rp_map, hash_map))
                        })();
                        let conn = credman.into_session().into_session().into_connection();
                        (result, conn)
                    }
                }
            })?;

        self.rps = rp_map;
        self.rp_hashes = hash_map;
        Ok(())
    }
}

impl RpcNode for CredentialsRpsNode {
    fn list_children(&mut self) -> BTreeMap<String, Value> {
        self.rps.clone()
    }

    fn call_action(
        &mut self,
        action: &str,
        _params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        Err(RpcError::no_such_action(action))
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        if !self.rps.contains_key(name) {
            return Err(RpcError::no_such_node(name));
        }

        let rp_id_hash = self
            .rp_hashes
            .get(name)
            .ok_or_else(|| RpcError::no_such_node(name))?
            .clone();

        let token = self.token.clone();
        let protocol = self.protocol;

        let creds: BTreeMap<String, Value> = with_ctap2!(&mut self.fido_conn, |ctap2| {
            match CredentialManagement::new(ctap2, protocol, token) {
                Err((e, s)) => {
                    let conn = s.into_session().into_connection();
                    (Err(RpcError::new("device-error", format!("{e}"))), conn)
                }
                Ok(mut credman) => {
                    let result = (|| -> Result<_, RpcError> {
                        let cred_list = credman
                            .enumerate_creds(&rp_id_hash)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                        let mut creds = BTreeMap::new();
                        for cred_info in &cred_list {
                            let id_hex = hex::encode(&cred_info.credential_id.id);
                            creds.insert(
                                id_hex.clone(),
                                json!({
                                    "user_name": cred_info.user.name,
                                    "display_name": cred_info.user.display_name,
                                    "user_id": hex::encode(&cred_info.user.id),
                                    "credential_id": {
                                        "id": id_hex,
                                        "type": "public-key",
                                    },
                                }),
                            );
                        }
                        Ok(creds)
                    })();
                    let conn = credman.into_session().into_session().into_connection();
                    (result, conn)
                }
            }
        })?;

        let fido_conn = std::mem::replace(
            &mut self.fido_conn,
            FidoConn::Hid {
                conn: None,
                shared: Arc::new(std::sync::Mutex::new(None)),
            },
        );

        Ok(Box::new(CredentialsRpNode {
            fido_conn,
            token: self.token.clone(),
            protocol: self.protocol,
            creds,
        }))
    }

    fn close(&mut self) {
        self.fido_conn.close();
    }
}

// --- CredentialsRpNode ---

struct CredentialsRpNode {
    fido_conn: FidoConn,
    token: Vec<u8>,
    protocol: PinProtocol,
    creds: BTreeMap<String, Value>,
}

impl RpcNode for CredentialsRpNode {
    fn list_children(&mut self) -> BTreeMap<String, Value> {
        self.creds.clone()
    }

    fn call_action(
        &mut self,
        action: &str,
        _params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        Err(RpcError::no_such_action(action))
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        if !self.creds.contains_key(name) {
            return Err(RpcError::no_such_node(name));
        }

        let cred_data = self.creds.get(name).unwrap().clone();
        let cred_id_hex = name.to_string();

        let fido_conn = std::mem::replace(
            &mut self.fido_conn,
            FidoConn::Hid {
                conn: None,
                shared: Arc::new(std::sync::Mutex::new(None)),
            },
        );

        Ok(Box::new(CredentialNode {
            fido_conn,
            token: self.token.clone(),
            protocol: self.protocol,
            cred_id_hex,
            data: cred_data,
        }))
    }

    fn close(&mut self) {
        self.fido_conn.close();
    }
}

// --- CredentialNode ---

struct CredentialNode {
    fido_conn: FidoConn,
    token: Vec<u8>,
    protocol: PinProtocol,
    cred_id_hex: String,
    data: Value,
}

impl RpcNode for CredentialNode {
    fn get_data(&self) -> Value {
        self.data.clone()
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["delete"]
    }

    fn call_action(
        &mut self,
        action: &str,
        _params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "delete" => {
                let cred_id_bytes = hex::decode(&self.cred_id_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid credential ID"))?;
                let token = self.token.clone();
                let protocol = self.protocol;

                with_ctap2!(&mut self.fido_conn, |ctap2| {
                    match CredentialManagement::new(ctap2, protocol, token) {
                        Err((e, s)) => {
                            let conn = s.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(mut credman) => {
                            let cred_id = PublicKeyCredentialDescriptor {
                                type_: yubikit::webauthn::PublicKeyCredentialType::PublicKey,
                                id: cred_id_bytes.clone(),
                                transports: None,
                            };
                            let result = credman
                                .delete_cred(&cred_id)
                                .map_err(|e| RpcError::new("device-error", format!("{e}")));
                            let conn = credman.into_session().into_session().into_connection();
                            (result, conn)
                        }
                    }
                })?;
                Ok(RpcResponse::new(json!({})))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        self.fido_conn.close();
    }
}

// --- FingerprintsNode ---

type SharedTemplates = Arc<std::sync::Mutex<BTreeMap<String, Option<String>>>>;

struct FingerprintsNode {
    fido_conn: FidoConn,
    token: Vec<u8>,
    protocol: PinProtocol,
    templates: SharedTemplates,
}

impl FingerprintsNode {
    fn new_hid(
        conn: Box<dyn FidoConnection + Send>,
        shared: SharedConn<Box<dyn FidoConnection + Send>>,
        token: Vec<u8>,
        protocol: PinProtocol,
    ) -> Result<Self, RpcError> {
        let mut node = Self {
            fido_conn: FidoConn::Hid {
                conn: Some(conn),
                shared,
            },
            token,
            protocol,
            templates: Arc::new(std::sync::Mutex::new(BTreeMap::new())),
        };
        node.refresh()?;
        Ok(node)
    }

    fn new_smartcard(
        conn: Box<dyn SmartCardConnection + Send>,
        shared: SharedConn<Box<dyn SmartCardConnection + Send>>,
        token: Vec<u8>,
        protocol: PinProtocol,
    ) -> Result<Self, RpcError> {
        let mut node = Self {
            fido_conn: FidoConn::SmartCard {
                conn: Some(conn),
                shared,
            },
            token,
            protocol,
            templates: Arc::new(std::sync::Mutex::new(BTreeMap::new())),
        };
        node.refresh()?;
        Ok(node)
    }

    fn refresh(&mut self) -> Result<(), RpcError> {
        self.templates.lock().unwrap().clear();
        let token = self.token.clone();
        let protocol = self.protocol;

        let templates: BTreeMap<String, Option<String>> =
            with_ctap2!(&mut self.fido_conn, |ctap2| {
                match BioEnrollment::new(ctap2, protocol, token) {
                    Err((e, s)) => {
                        let conn = s.into_session().into_connection();
                        (Err(RpcError::new("device-error", format!("{e}"))), conn)
                    }
                    Ok(mut bio) => {
                        let mut templates = BTreeMap::new();
                        let result = match bio.enumerate_enrollments() {
                            Ok(enrollments) => {
                                for fp in &enrollments {
                                    let name = fp
                                        .name
                                        .as_deref()
                                        .filter(|n| !n.is_empty())
                                        .map(String::from);
                                    templates.insert(hex::encode(&fp.id), name);
                                }
                                Ok(templates)
                            }
                            Err(Ctap2Error::StatusError(CtapStatus::InvalidOption)) => {
                                Ok(templates)
                            }
                            Err(e) => Err(RpcError::new("device-error", format!("{e}"))),
                        };
                        let conn = bio.into_session().into_session().into_connection();
                        (result, conn)
                    }
                }
            })?;

        *self.templates.lock().unwrap() = templates;
        Ok(())
    }
}

impl RpcNode for FingerprintsNode {
    fn list_children(&mut self) -> BTreeMap<String, Value> {
        self.templates
            .lock()
            .unwrap()
            .iter()
            .map(|(id, name)| (id.clone(), json!({"name": name})))
            .collect()
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["add"]
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "add" => {
                let name = params
                    .get("name")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let token = self.token.clone();
                let protocol = self.protocol;

                let result: (String, Option<String>) = with_ctap2!(&mut self.fido_conn, |ctap2| {
                    match BioEnrollment::new(ctap2, protocol, token) {
                        Err((e, s)) => {
                            let conn = s.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(mut bio) => {
                            let is_cancelled = || cancel.load(Ordering::Relaxed);
                            let result = enroll_fingerprint(&mut bio, &name, signal, &is_cancelled);
                            let conn = bio.into_session().into_session().into_connection();
                            (result, conn)
                        }
                    }
                })?;

                let (template_id_hex, fp_name) = result;
                self.templates
                    .lock()
                    .unwrap()
                    .insert(template_id_hex.clone(), fp_name.clone());

                Ok(RpcResponse::new(json!({
                    "template_id": template_id_hex,
                    "name": fp_name,
                })))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let templates = self.templates.lock().unwrap();
        if !templates.contains_key(name) {
            return Err(RpcError::no_such_node(name));
        }

        let template_id_hex = name.to_string();
        let fp_name = templates.get(name).unwrap().clone();
        drop(templates);

        let fido_conn = std::mem::replace(
            &mut self.fido_conn,
            FidoConn::Hid {
                conn: None,
                shared: Arc::new(std::sync::Mutex::new(None)),
            },
        );

        Ok(Box::new(FingerprintNode {
            fido_conn,
            token: self.token.clone(),
            protocol: self.protocol,
            template_id_hex,
            name: fp_name,
            parent_templates: self.templates.clone(),
        }))
    }

    fn close(&mut self) {
        self.fido_conn.close();
    }
}

// --- FingerprintNode ---

struct FingerprintNode {
    fido_conn: FidoConn,
    token: Vec<u8>,
    protocol: PinProtocol,
    template_id_hex: String,
    name: Option<String>,
    parent_templates: SharedTemplates,
}

impl RpcNode for FingerprintNode {
    fn get_data(&self) -> Value {
        json!({
            "template_id": self.template_id_hex,
            "name": self.name,
        })
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["rename", "delete"]
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "rename" => {
                let new_name = params
                    .get("name")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing name"))?
                    .to_string();

                let template_id = hex::decode(&self.template_id_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid template ID"))?;
                let token = self.token.clone();
                let protocol = self.protocol;

                with_ctap2!(&mut self.fido_conn, |ctap2| {
                    match BioEnrollment::new(ctap2, protocol, token) {
                        Err((e, s)) => {
                            let conn = s.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(mut bio) => {
                            let result = bio
                                .set_name(&template_id, &new_name)
                                .map_err(|e| RpcError::new("device-error", format!("{e}")));
                            let conn = bio.into_session().into_session().into_connection();
                            (result, conn)
                        }
                    }
                })?;
                self.name = Some(new_name.clone());
                self.parent_templates
                    .lock()
                    .unwrap()
                    .insert(self.template_id_hex.clone(), Some(new_name));
                Ok(RpcResponse::new(json!({})))
            }
            "delete" => {
                let template_id = hex::decode(&self.template_id_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid template ID"))?;
                let token = self.token.clone();
                let protocol = self.protocol;

                with_ctap2!(&mut self.fido_conn, |ctap2| {
                    match BioEnrollment::new(ctap2, protocol, token) {
                        Err((e, s)) => {
                            let conn = s.into_session().into_connection();
                            (Err(RpcError::new("device-error", format!("{e}"))), conn)
                        }
                        Ok(mut bio) => {
                            let result = bio
                                .remove_enrollment(&template_id)
                                .map_err(|e| RpcError::new("device-error", format!("{e}")));
                            let conn = bio.into_session().into_session().into_connection();
                            (result, conn)
                        }
                    }
                })?;
                self.parent_templates
                    .lock()
                    .unwrap()
                    .remove(&self.template_id_hex);
                Ok(RpcResponse::new(json!({})))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        self.fido_conn.close();
    }
}

// --- Bio enrollment helper ---

fn map_ctap_enroll_error<E: std::error::Error + Send + Sync + 'static>(
    e: Ctap2Error<E>,
) -> RpcError {
    if matches!(&e, Ctap2Error::StatusError(CtapStatus::UserActionTimeout)) {
        RpcError::timeout()
    } else {
        RpcError::new("device-error", format!("{e}"))
    }
}

fn enroll_fingerprint<C: yubikit::core::Connection + 'static>(
    bio: &mut BioEnrollment<C>,
    name: &Option<String>,
    signal: SignalFn,
    is_cancelled: &dyn Fn() -> bool,
) -> Result<(String, Option<String>), RpcError> {
    let resp = bio
        .enroll_begin(None, Some(&mut |_| {}), Some(is_cancelled))
        .map_err(map_ctap_enroll_error)?;

    let template_id = resp.template_id;
    let status = resp.last_sample_status;
    let mut remaining = resp.remaining_samples;

    if status != 0 {
        signal("capture-error", json!({"code": status}));
    } else {
        signal("capture", json!({"remaining": remaining}));
    }

    while remaining > 0 {
        let resp = bio
            .enroll_capture_next(&template_id, None, Some(&mut |_| {}), Some(is_cancelled))
            .map_err(map_ctap_enroll_error)?;

        if resp.last_sample_status != 0 {
            signal("capture-error", json!({"code": resp.last_sample_status}));
        } else {
            signal("capture", json!({"remaining": resp.remaining_samples}));
        }
        remaining = resp.remaining_samples;
    }

    if let Some(n) = name {
        bio.set_name(&template_id, n)
            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
    }

    Ok((hex::encode(&template_id), name.clone()))
}
