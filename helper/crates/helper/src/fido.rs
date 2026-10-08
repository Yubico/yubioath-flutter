use std::collections::BTreeMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use serde_json::{Value, json};

use yubikit::cbor::Value as CborValue;
use yubikit::core::Transport;
use yubikit::ctap::CtapSession;
use yubikit::ctap2::{
    BioEnrollment, ClientPin, Config, CredentialManagement, Ctap2Error, Ctap2Pin, Ctap2Session,
    CtapStatus, Info, Permissions, PinProtocol, PublicKeyCredentialDescriptor,
};
use yubikit::device::{DeviceError, ReinsertStatus, YubiKeyDevice};
use yubikit::fido::{FidoConnection, FidoError};
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
            ppuats: AppData::new("ppuats").expect("failed to open PPUAT app data"),
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
    retries: (u32, Option<u32>),
) -> RpcError {
    if let Ctap2Error::StatusError(status) = e {
        match status {
            CtapStatus::PinInvalid | CtapStatus::PinBlocked | CtapStatus::PinAuthBlocked => {
                return RpcError::with_body(
                    "pin-validation",
                    "Authentication is required",
                    json!({
                        "retries": retries.0,
                        "power_cycle": retries.1,
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

fn open_fido_after_reinsert(
    device: &dyn YubiKeyDevice,
) -> Result<Box<dyn FidoConnection + Send>, RpcError> {
    let mut retries = 0;
    loop {
        match device.open_fido() {
            Ok(conn) => return Ok(conn),
            Err(e) => {
                let wrong_nonce = matches!(
                    &e,
                    DeviceError::Transport(source)
                        if matches!(source.downcast_ref::<FidoError>(), Some(FidoError::WrongNonce))
                );
                if wrong_nonce && retries < 2 {
                    retries += 1;
                    log::warn!("FIDO INIT collided after reinsertion; retrying ({retries}/2)");
                    std::thread::sleep(Duration::from_millis(100));
                } else {
                    return Err(RpcError::new("connection-error", format!("{e}")));
                }
            }
        }
    }
}

#[derive(Default)]
struct ResetKeepalive {
    touch_required: bool,
    waiting: bool,
}

impl ResetKeepalive {
    fn update(&mut self, status: u8) -> bool {
        match status {
            0x02 if !self.waiting => self.touch_required = true,
            0x01 if self.touch_required && !self.waiting => {
                self.waiting = true;
                return true;
            }
            _ => {}
        }
        false
    }
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
        _ => Value::Null,
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
            FidoConn::Hid { conn, shared } => {
                match conn.take().or_else(|| shared.lock().unwrap().take()) {
                    None => Err(RpcError::new("connection-error", "Connection in use")),
                    Some(c) => match CtapSession::new_fido(c) {
                        Err((e, c)) => {
                            *conn = Some(c);
                            Err(RpcError::new("device-error", format!("{e}")))
                        }
                        Ok(ctap) => match Ctap2Session::new(ctap) {
                            Err((e, s)) => {
                                *conn = Some(s.into_connection());
                                Err(RpcError::new("device-error", format!("{e}")))
                            }
                            Ok($session) => {
                                let (result, returned_c) = { $body };
                                *conn = Some(returned_c);
                                result
                            }
                        },
                    },
                }
            }
            FidoConn::SmartCard { conn, shared } => {
                match conn.take().or_else(|| shared.lock().unwrap().take()) {
                    None => Err(RpcError::new("connection-error", "Connection in use")),
                    Some(c) => match CtapSession::new(c) {
                        Err((e, c)) => {
                            *conn = Some(c);
                            Err(RpcError::new("device-error", format!("{e}")))
                        }
                        Ok(ctap) => match Ctap2Session::new(ctap) {
                            Err((e, s)) => {
                                *conn = Some(s.into_connection());
                                Err(RpcError::new("device-error", format!("{e}")))
                            }
                            Ok($session) => {
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

/// Same as `with_ctap2!` but for `FidoDeviceType`.
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
                            Err((e, s)) => {
                                *conn = Some(s.into_connection());
                                Err(RpcError::new("device-error", format!("{e}")))
                            }
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
                            Err((e, s)) => {
                                *conn = Some(s.into_connection());
                                Err(RpcError::new("device-error", format!("{e}")))
                            }
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
        if let Err(e) = node.refresh_data() {
            node.close();
            return Err(e);
        }
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
        if let Err(e) = node.refresh_data() {
            node.close();
            return Err(e);
        }
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

    fn refresh_data(&mut self) -> Result<(), RpcError> {
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
                                    let result = match client_pin.get_pin_retries() {
                                        Ok((pin_retries, power_cycle)) => {
                                            data["pin_retries"] = json!(pin_retries);
                                            data["power_cycle"] = json!(power_cycle);
                                            if has_bio {
                                                let uv_retries =
                                                    client_pin.get_uv_retries().unwrap_or(0);
                                                data["uv_retries"] = json!(uv_retries);
                                            }
                                            Ok((data, info))
                                        }
                                        Err(e) => {
                                            Err(RpcError::new("device-error", format!("{e}")))
                                        }
                                    };
                                    let conn =
                                        client_pin.into_session().into_session().into_connection();
                                    (result, conn)
                                }
                            }
                        } else {
                            let conn = ctap2.into_session().into_connection();
                            (Ok((data, info)), conn)
                        }
                    }
                }
            });
        let (d, info) = data?;
        self.cached_data = d;
        // Try to load a stored PPUAT on first refresh (construction).
        if self.ppuat.is_none() {
            self.load_ppuat(&info);
        }
        Ok(())
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
        let mut keepalive = ResetKeepalive::default();
        let mut on_keepalive = |status| {
            if keepalive.update(status) {
                signal("reset", json!({"state": "wait"}));
            }
        };

        // Re-open connection and perform reset based on type
        match &mut self.device_type {
            FidoDeviceType::Hid { conn, .. } => {
                let new_conn = open_fido_after_reinsert(device.as_ref())?;
                let ctap = CtapSession::new_fido(new_conn)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;
                let mut ctap2 = Ctap2Session::new(ctap)
                    .map_err(|(e, _)| RpcError::new("device-error", format!("{e}")))?;

                signal("reset", json!({"state": "touch"}));
                let result = ctap2
                    .reset(Some(&mut on_keepalive), Some(&is_cancelled))
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
                    .reset(Some(&mut on_keepalive), Some(&is_cancelled))
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
        params: &Value,
        signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let result = self.do_call_action(action, params, signal, cancel);
        if let Err(ref e) = result
            && e.status == "pin-validation"
        {
            self.pin_token = None;
            self.cached_data["pin_retries"] = e.body["retries"].clone();
            self.cached_data["power_cycle"] = e.body["power_cycle"].clone();
        }
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
        params: &Value,
        signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "unlock" => {
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing pin"))?;
                let pin = Ctap2Pin::new(pin).map_err(RpcError::invalid_params)?;
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
                                    let ppuat_result =
                                        if remember && self.ppuat.is_none() && supports_readonly {
                                            client_pin
                                                .get_pin_token(
                                                    &pin,
                                                    Some(Permissions::PERSISTENT_CREDENTIAL_MGMT),
                                                    None,
                                                )
                                                .map(|ppuat| {
                                                    let ident = info.get_identifier(&ppuat);
                                                    ident.map(|id| (ppuat, id))
                                                })
                                        } else {
                                            Ok(None)
                                        };

                                    // Get the regular token
                                    let token_result = ppuat_result.and_then(|ppuat_data| {
                                        client_pin
                                            .get_pin_token(&pin, perms, rpid)
                                            .map(|token| (token, ppuat_data))
                                    });
                                    match token_result {
                                        Ok((token, ppuat_data)) => {
                                            let protocol = client_pin.protocol();
                                            let conn = client_pin
                                                .into_session()
                                                .into_session()
                                                .into_connection();
                                            (Ok((token, protocol, ppuat_data)), conn)
                                        }
                                        Err(e) => {
                                            let error = match client_pin.get_pin_retries() {
                                                Ok(retries) => handle_pin_error(&e, retries),
                                                Err(retry_error) => RpcError::new(
                                                    "device-error",
                                                    format!(
                                                        "Failed to read PIN retries after {e}: {retry_error}"
                                                    ),
                                                ),
                                            };
                                            let conn = client_pin
                                                .into_session()
                                                .into_session()
                                                .into_connection();
                                            (Err(error), conn)
                                        }
                                    }
                                }
                            }
                        }
                    }
                });
                let (token, protocol, ppuat_data) = result?;
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

                self.refresh_data()?;
                Ok(RpcResponse::new(json!({})))
            }
            "set_pin" => {
                let new_pin = params
                    .get("new_pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing new_pin"))?;
                let new_pin = Ctap2Pin::new(new_pin).map_err(RpcError::invalid_params)?;
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .map(Ctap2Pin::new)
                    .transpose()
                    .map_err(RpcError::invalid_params)?;

                let result = with_ctap2_dev!(&mut self.device_type, |ctap2| {
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
                                            client_pin.change_pin(pin.as_ref().unwrap(), &new_pin)
                                        } else {
                                            client_pin.set_pin(&new_pin)
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
                                                let error = match client_pin.get_pin_retries() {
                                                    Ok(retries) => handle_pin_error(&e, retries),
                                                    Err(retry_error) => RpcError::new(
                                                        "device-error",
                                                        format!(
                                                            "Failed to read PIN retries after {e}: {retry_error}"
                                                        ),
                                                    ),
                                                };
                                                let conn = client_pin
                                                    .into_session()
                                                    .into_session()
                                                    .into_connection();
                                                (Err(error), conn)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                });
                result?;
                self.pin_token = None;
                self.delete_ppuat();
                self.refresh_data()?;
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
    fn take_for_child(&mut self) -> Result<Self, RpcError> {
        // Keep the parent's transport and return channel when lending to a child.
        match self {
            FidoConn::Hid { conn, shared } => Ok(Self::Hid {
                conn: Some(
                    conn.take()
                        .or_else(|| shared.lock().unwrap().take())
                        .ok_or_else(|| RpcError::new("connection-error", "Connection in use"))?,
                ),
                shared: shared.clone(),
            }),
            FidoConn::SmartCard { conn, shared } => Ok(Self::SmartCard {
                conn: Some(
                    conn.take()
                        .or_else(|| shared.lock().unwrap().take())
                        .ok_or_else(|| RpcError::new("connection-error", "Connection in use"))?,
                ),
                shared: shared.clone(),
            }),
        }
    }

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
        _params: &Value,
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

        let fido_conn = self.fido_conn.take_for_child()?;

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
        _params: &Value,
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

        let fido_conn = self.fido_conn.take_for_child()?;

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
        _params: &Value,
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
        params: &Value,
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

        let fido_conn = self.fido_conn.take_for_child()?;

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
        params: &Value,
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

#[cfg(test)]
mod pin_tests {
    use super::*;
    use sha2::{Digest, Sha256};
    use yubikit::core::{Connection, Version};
    use yubikit::fido::CtapHidCapability;
    use yubikit::smartcard::SmartCardError;

    struct PinState {
        retries: u32,
        power_cycle: bool,
        fail_info: bool,
        fail_retries: bool,
        readonly: bool,
        token_requests: u32,
        last_permissions: Option<i64>,
        fail_credentials: bool,
        fail_delete: bool,
        deleted_credentials: Vec<u8>,
        fingerprints: BTreeMap<u8, String>,
    }

    fn response(value: CborValue) -> Vec<u8> {
        let mut response = vec![0];
        response.extend(value.encode());
        response
    }

    impl PinState {
        fn call(&mut self, data: &[u8]) -> Vec<u8> {
            match data[0] {
                0x04 if self.fail_info => vec![CtapStatus::Other as u8],
                0x04 => response(CborValue::Map(vec![
                    (
                        CborValue::Int(1),
                        CborValue::Array(vec![CborValue::Text("FIDO_2_1".into())]),
                    ),
                    (CborValue::Int(3), CborValue::Bytes(vec![0; 16])),
                    (
                        CborValue::Int(4),
                        CborValue::Map(vec![
                            (CborValue::Text("clientPin".into()), CborValue::Bool(true)),
                            (CborValue::Text("credMgmt".into()), CborValue::Bool(true)),
                            (CborValue::Text("bioEnroll".into()), CborValue::Bool(true)),
                            (
                                CborValue::Text("pinUvAuthToken".into()),
                                CborValue::Bool(true),
                            ),
                            (
                                CborValue::Text("perCredMgmtRO".into()),
                                CborValue::Bool(self.readonly),
                            ),
                        ]),
                    ),
                    (CborValue::Int(6), CborValue::Array(vec![CborValue::Int(1)])),
                ])),
                0x06 => {
                    let args = yubikit::cbor::decode(&data[1..]).unwrap();
                    let command = args.map_get_int(2).unwrap().as_int().unwrap();
                    match command {
                        1 if self.fail_retries => vec![CtapStatus::Other as u8],
                        1 => response(CborValue::Map(vec![
                            (CborValue::Int(3), CborValue::Int(self.retries as i64)),
                            (
                                CborValue::Int(4),
                                CborValue::Int(i64::from(self.power_cycle)),
                            ),
                        ])),
                        7 => response(CborValue::Map(vec![(CborValue::Int(5), CborValue::Int(8))])),
                        2 => {
                            // Private key 1 makes the shared point equal to the peer's public key.
                            let x = hex::decode(
                                "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
                            )
                            .unwrap();
                            let y = hex::decode(
                                "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5",
                            )
                            .unwrap();
                            response(CborValue::Map(vec![(
                                CborValue::Int(1),
                                CborValue::Map(vec![
                                    (CborValue::Int(1), CborValue::Int(2)),
                                    (CborValue::Int(3), CborValue::Int(-25)),
                                    (CborValue::Int(-1), CborValue::Int(1)),
                                    (CborValue::Int(-2), CborValue::Bytes(x)),
                                    (CborValue::Int(-3), CborValue::Bytes(y)),
                                ]),
                            )]))
                        }
                        4 | 5 | 9 => {
                            self.token_requests += 1;
                            self.last_permissions = args.map_get_int(9).and_then(CborValue::as_int);
                            if self.retries == 0 {
                                return vec![CtapStatus::PinBlocked as u8];
                            }
                            if self.power_cycle {
                                return vec![CtapStatus::PinAuthBlocked as u8];
                            }
                            let peer = args.map_get_int(3).unwrap();
                            let x = peer.map_get_int(-2).unwrap().as_bytes().unwrap();
                            let secret = Sha256::digest(x);
                            let encrypted = args.map_get_int(6).unwrap().as_bytes().unwrap();
                            let hash = PinProtocol::V1.decrypt(&secret, encrypted).unwrap();
                            if hash != Sha256::digest(b"123456")[..16] {
                                self.retries -= 1;
                                return vec![CtapStatus::PinInvalid as u8];
                            }
                            self.retries = 8;
                            if command == 4 {
                                return vec![0];
                            }
                            response(CborValue::Map(vec![(
                                CborValue::Int(2),
                                CborValue::Bytes(PinProtocol::V1.encrypt(&secret, &[0x42; 32])),
                            )]))
                        }
                        _ => panic!("Unexpected ClientPIN command: {command}"),
                    }
                }
                0x09 => {
                    let args = yubikit::cbor::decode(&data[1..]).unwrap();
                    let command = args.map_get_int(2).unwrap().as_int().unwrap();
                    match command {
                        4 => response(CborValue::Map(vec![(
                            CborValue::Int(7),
                            CborValue::Array(
                                self.fingerprints
                                    .iter()
                                    .map(|(id, name)| {
                                        CborValue::Map(vec![
                                            (CborValue::Int(1), CborValue::Bytes(vec![*id])),
                                            (CborValue::Int(2), CborValue::Text(name.clone())),
                                        ])
                                    })
                                    .collect(),
                            ),
                        )])),
                        5 | 6 => {
                            let params = args.map_get_int(3).unwrap();
                            let id = params.map_get_int(1).unwrap().as_bytes().unwrap()[0];
                            if command == 5 {
                                let name = params.map_get_int(2).unwrap().as_text().unwrap();
                                self.fingerprints.insert(id, name.to_string());
                            } else {
                                self.fingerprints.remove(&id);
                            }
                            vec![0]
                        }
                        _ => panic!("Unexpected bio enrollment command: {command}"),
                    }
                }
                0x0a => {
                    let args = yubikit::cbor::decode(&data[1..]).unwrap();
                    let command = args.map_get_int(1).unwrap().as_int().unwrap();
                    match command {
                        1 => response(CborValue::Map(vec![
                            (
                                CborValue::Int(1),
                                CborValue::Int(2 - self.deleted_credentials.len() as i64),
                            ),
                            (CborValue::Int(2), CborValue::Int(98)),
                        ])),
                        2 | 3 => {
                            let id = if command == 2 { 1 } else { 2 };
                            response(CborValue::Map(vec![
                                (
                                    CborValue::Int(3),
                                    CborValue::Map(vec![(
                                        CborValue::Text("id".into()),
                                        CborValue::Text(format!("site{id}.example")),
                                    )]),
                                ),
                                (CborValue::Int(4), CborValue::Bytes(vec![id; 32])),
                                (CborValue::Int(5), CborValue::Int(2)),
                            ]))
                        }
                        4 if self.fail_credentials => vec![CtapStatus::Other as u8],
                        4 => {
                            let params = args.map_get_int(2).unwrap();
                            let id = params.map_get_int(1).unwrap().as_bytes().unwrap()[0];
                            if self.deleted_credentials.contains(&id) {
                                return response(CborValue::Map(vec![(
                                    CborValue::Int(9),
                                    CborValue::Int(0),
                                )]));
                            }
                            response(CborValue::Map(vec![
                                (
                                    CborValue::Int(6),
                                    CborValue::Map(vec![
                                        (CborValue::Text("id".into()), CborValue::Bytes(vec![id])),
                                        (
                                            CborValue::Text("name".into()),
                                            CborValue::Text(format!("user{id}")),
                                        ),
                                    ]),
                                ),
                                (
                                    CborValue::Int(7),
                                    CborValue::Map(vec![
                                        (CborValue::Text("id".into()), CborValue::Bytes(vec![id])),
                                        (
                                            CborValue::Text("type".into()),
                                            CborValue::Text("public-key".into()),
                                        ),
                                    ]),
                                ),
                                (CborValue::Int(8), CborValue::Map(vec![])),
                                (CborValue::Int(9), CborValue::Int(1)),
                            ]))
                        }
                        6 if self.fail_delete => vec![CtapStatus::Other as u8],
                        6 => {
                            let params = args.map_get_int(2).unwrap();
                            let descriptor = params.map_get_int(2).unwrap();
                            let id = descriptor.map_get_text("id").unwrap().as_bytes().unwrap()[0];
                            self.deleted_credentials.push(id);
                            vec![0]
                        }
                        _ => panic!("Unexpected credential management command: {command}"),
                    }
                }
                command => panic!("Unexpected CTAP2 command: {command:02x}"),
            }
        }
    }

    struct Hid(Arc<StdMutex<PinState>>);

    impl Connection for Hid {
        type Error = FidoError;
        fn close(&mut self) {}
    }

    impl FidoConnection for Hid {
        fn call(
            &mut self,
            cmd: u8,
            data: &[u8],
            _on_keepalive: Option<&mut dyn FnMut(u8)>,
            _cancel: Option<&dyn Fn() -> bool>,
        ) -> Result<Vec<u8>, FidoError> {
            assert_eq!(cmd, 0x10);
            Ok(self.0.lock().unwrap().call(data))
        }

        fn device_version(&self) -> Version {
            Version(5, 2, 6)
        }

        fn capabilities(&self) -> CtapHidCapability {
            CtapHidCapability::from_raw(CtapHidCapability::CBOR)
        }
    }

    struct SmartCard(Arc<StdMutex<PinState>>);

    impl Connection for SmartCard {
        type Error = SmartCardError;
        fn close(&mut self) {}
    }

    impl SmartCardConnection for SmartCard {
        fn send_and_receive(&mut self, apdu: &[u8]) -> Result<(Vec<u8>, u16), SmartCardError> {
            match apdu[1] {
                0xa4 => Ok((b"U2F_V2".to_vec(), 0x9000)),
                0x10 => {
                    let (offset, length) = if apdu[4] == 0 {
                        (7, u16::from_be_bytes([apdu[5], apdu[6]]) as usize)
                    } else {
                        (5, apdu[4] as usize)
                    };
                    Ok((
                        self.0.lock().unwrap().call(&apdu[offset..offset + length]),
                        0x9000,
                    ))
                }
                instruction => panic!("Unexpected APDU instruction: {instruction:02x}"),
            }
        }

        fn transport(&self) -> Transport {
            Transport::Nfc
        }
    }

    fn node(smartcard: bool) -> (Ctap2Node, Arc<StdMutex<PinState>>) {
        let state = Arc::new(StdMutex::new(PinState {
            retries: 8,
            power_cycle: false,
            fail_info: false,
            fail_retries: false,
            readonly: false,
            token_requests: 0,
            last_permissions: None,
            fail_credentials: false,
            fail_delete: false,
            deleted_credentials: vec![],
            fingerprints: BTreeMap::from([(1, "First".into()), (2, "Second".into())]),
        }));
        let node = if smartcard {
            Ctap2Node::new_smartcard(
                Box::new(SmartCard(state.clone())),
                Arc::new(StdMutex::new(None)),
                None,
            )
        } else {
            Ctap2Node::new_hid(
                Box::new(Hid(state.clone())),
                Arc::new(StdMutex::new(None)),
                None,
            )
        }
        .unwrap();
        (node, state)
    }

    fn action(node: &mut Ctap2Node, action: &str, params: Value) -> Result<RpcResponse, RpcError> {
        node.call_action(action, &params, &|_, _| {}, &AtomicBool::new(false))
    }

    fn rpc_call(
        host: &mut crate::rpc::NodeHost,
        action: &str,
        target: &[&str],
        params: Value,
    ) -> Result<RpcResponse, RpcError> {
        host.call(
            action,
            &target
                .iter()
                .map(|part| part.to_string())
                .collect::<Vec<_>>(),
            &params,
            &|_, _| {},
            &AtomicBool::new(false),
        )
    }

    #[test]
    fn fingerprint_children_preserve_shared_connection_when_switching() {
        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            let mut host = crate::rpc::NodeHost::new(Box::new(node));
            rpc_call(&mut host, "fingerprints", &[], json!({})).unwrap();
            for id in ["01", "02", "01"] {
                rpc_call(
                    &mut host,
                    "rename",
                    &["fingerprints", id],
                    json!({"name": "Renamed"}),
                )
                .unwrap();
            }
            rpc_call(&mut host, "delete", &["fingerprints", "02"], json!({})).unwrap();
            assert_eq!(
                state.lock().unwrap().fingerprints,
                BTreeMap::from([(1, "Renamed".into())])
            );
            rpc_call(&mut host, "close", &[], json!({"child": "fingerprints"})).unwrap();
            rpc_call(&mut host, "unlock", &[], json!({"pin": "123456"})).unwrap();
        }
    }

    #[test]
    fn lists_multiple_relying_parties_and_returns_connection_after_deletion() {
        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            let mut host = crate::rpc::NodeHost::new(Box::new(node));
            let rps = rpc_call(&mut host, "credentials", &[], json!({})).unwrap();
            assert_eq!(rps.body["children"].as_object().unwrap().len(), 2);

            for _ in 0..2 {
                for id in [1, 2] {
                    let rp = format!("site{id}.example");
                    let result = rpc_call(&mut host, &rp, &["credentials"], json!({})).unwrap();
                    let credential = format!("{id:02x}");
                    assert_eq!(
                        result.body["children"][&credential]["user_name"],
                        format!("user{id}")
                    );
                    let result = rpc_call(
                        &mut host,
                        "get",
                        &["credentials", &rp, &credential],
                        json!({}),
                    )
                    .unwrap();
                    assert_eq!(result.body["data"]["user_id"], credential);
                }
            }

            rpc_call(
                &mut host,
                "delete",
                &["credentials", "site1.example", "01"],
                json!({}),
            )
            .unwrap();
            assert_eq!(state.lock().unwrap().deleted_credentials, vec![1]);
            rpc_call(&mut host, "close", &[], json!({"child": "credentials"})).unwrap();
            rpc_call(&mut host, "credentials", &[], json!({})).unwrap();
            let result = rpc_call(&mut host, "site1.example", &["credentials"], json!({})).unwrap();
            assert!(result.body["children"].as_object().unwrap().is_empty());
            let result = rpc_call(&mut host, "site2.example", &["credentials"], json!({})).unwrap();
            assert_eq!(result.body["children"].as_object().unwrap().len(), 1);
            rpc_call(&mut host, "close", &[], json!({"child": "credentials"})).unwrap();
            rpc_call(&mut host, "unlock", &[], json!({"pin": "123456"})).unwrap();
        }
    }

    #[test]
    fn credential_errors_allow_retrying_and_switching_relying_parties() {
        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            let mut host = crate::rpc::NodeHost::new(Box::new(node));
            rpc_call(&mut host, "credentials", &[], json!({})).unwrap();
            rpc_call(&mut host, "site1.example", &["credentials"], json!({})).unwrap();

            state.lock().unwrap().fail_credentials = true;
            let error = rpc_call(&mut host, "site2.example", &["credentials"], json!({}))
                .err()
                .unwrap();
            assert_eq!(error.status, "device-error");
            state.lock().unwrap().fail_credentials = false;
            rpc_call(&mut host, "site2.example", &["credentials"], json!({})).unwrap();

            state.lock().unwrap().fail_delete = true;
            let error = rpc_call(
                &mut host,
                "delete",
                &["credentials", "site2.example", "02"],
                json!({}),
            )
            .err()
            .unwrap();
            assert_eq!(error.status, "device-error");
            assert!(state.lock().unwrap().deleted_credentials.is_empty());
            state.lock().unwrap().fail_delete = false;
            rpc_call(&mut host, "site1.example", &["credentials"], json!({})).unwrap();
            rpc_call(
                &mut host,
                "delete",
                &["credentials", "site2.example", "02"],
                json!({}),
            )
            .unwrap();
            assert_eq!(state.lock().unwrap().deleted_credentials, vec![2]);
        }
    }

    #[test]
    fn wrong_then_correct_pin_updates_reported_retries() {
        for smartcard in [false, true] {
            let (mut node, _) = node(smartcard);
            let error = action(&mut node, "unlock", json!({"pin": "654321"}))
                .err()
                .unwrap();
            assert_eq!(error.status, "pin-validation");
            assert_eq!(error.body["retries"], 7);
            assert_eq!(node.get_data()["pin_retries"], 7);
            assert_eq!(node.get_data()["unlocked"], false);
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            assert_eq!(node.get_data()["pin_retries"], 8);
            assert_eq!(node.get_data()["unlocked"], true);
        }
    }

    #[test]
    fn invalid_lengths_do_not_lose_connection_or_consume_retries() {
        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            for pin in ["".to_string(), "123".into(), "1".repeat(241)] {
                for (action_name, params) in [
                    ("unlock", json!({"pin": pin})),
                    ("unlock", json!({"pin": pin, "remember": true})),
                    ("set_pin", json!({"pin": "123456", "new_pin": pin})),
                    ("set_pin", json!({"pin": pin, "new_pin": "123456"})),
                ] {
                    let error = action(&mut node, action_name, params).err().unwrap();
                    assert_eq!(error.status, "invalid-command");
                    assert_eq!(node.get_data()["pin_retries"], 8);
                }
            }
            assert_eq!(state.lock().unwrap().token_requests, 0);
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            assert_eq!(node.get_data()["unlocked"], true);
        }
    }

    #[test]
    fn session_initialization_failure_does_not_lose_connection() {
        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            state.lock().unwrap().fail_info = true;
            let error = action(&mut node, "unlock", json!({"pin": "123456"}))
                .err()
                .unwrap();
            assert_eq!(error.status, "device-error");
            state.lock().unwrap().fail_info = false;
            action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
            assert_eq!(node.get_data()["unlocked"], true);
        }
    }

    #[test]
    fn node_initialization_failure_returns_connection_to_shared_owner() {
        fn reopen(node: &mut Ctap2Node) -> Result<Ctap2Node, RpcError> {
            node.close();
            match &mut node.device_type {
                FidoDeviceType::Hid { shared, .. } => {
                    let connection = shared.lock().unwrap().take().unwrap();
                    Ctap2Node::new_hid(connection, shared.clone(), None)
                }
                FidoDeviceType::SmartCard { shared, .. } => {
                    let connection = shared.lock().unwrap().take().unwrap();
                    Ctap2Node::new_smartcard(connection, shared.clone(), None)
                }
            }
        }

        for smartcard in [false, true] {
            let (mut node, state) = node(smartcard);
            state.lock().unwrap().fail_retries = true;
            let error = reopen(&mut node).err().unwrap();
            assert_eq!(error.status, "device-error");
            state.lock().unwrap().fail_retries = false;
            let recovered = reopen(&mut node).unwrap();
            assert_eq!(recovered.get_data()["pin_retries"], 8);
        }
    }

    #[test]
    fn remember_with_wrong_pin_consumes_only_one_attempt() {
        let (mut node, state) = node(false);
        state.lock().unwrap().readonly = true;
        let error = action(
            &mut node,
            "unlock",
            json!({"pin": "654321", "remember": true}),
        )
        .err()
        .unwrap();
        assert_eq!(error.status, "pin-validation");
        assert_eq!(error.body["retries"], 7);
        assert_eq!(state.lock().unwrap().token_requests, 1);
        assert_eq!(
            state.lock().unwrap().last_permissions,
            Some(Permissions::PERSISTENT_CREDENTIAL_MGMT.bits() as i64),
        );
        assert_eq!(node.get_data()["pin_retries"], 7);
    }

    #[test]
    fn retry_read_failure_is_not_reported_as_a_blocked_pin() {
        let (mut node, state) = node(false);
        state.lock().unwrap().fail_retries = true;
        let error = action(&mut node, "unlock", json!({"pin": "654321"}))
            .err()
            .unwrap();
        assert_eq!(error.status, "device-error");
        assert_eq!(node.get_data()["pin_retries"], 8);
        state.lock().unwrap().fail_retries = false;
        action(&mut node, "unlock", json!({"pin": "123456"})).unwrap();
    }

    #[test]
    fn pin_change_failure_updates_reported_retries() {
        for smartcard in [false, true] {
            let (mut node, _) = node(smartcard);
            let error = action(
                &mut node,
                "set_pin",
                json!({"pin": "654321", "new_pin": "123456"}),
            )
            .err()
            .unwrap();
            assert_eq!(error.status, "pin-validation");
            assert_eq!(node.get_data()["pin_retries"], 7);
            action(
                &mut node,
                "set_pin",
                json!({"pin": "123456", "new_pin": "123456"}),
            )
            .unwrap();
            assert_eq!(node.get_data()["pin_retries"], 8);
        }
    }

    #[test]
    fn blocked_pin_statuses_preserve_actual_retry_counts() {
        for (retries, power_cycle) in [(0, false), (6, true)] {
            let (mut node, state) = node(false);
            {
                let mut state = state.lock().unwrap();
                state.retries = retries;
                state.power_cycle = power_cycle;
            }
            let error = action(&mut node, "unlock", json!({"pin": "123456"}))
                .err()
                .unwrap();
            assert_eq!(error.status, "pin-validation");
            assert_eq!(error.body["auth_blocked"], power_cycle);
            assert_eq!(node.get_data()["pin_retries"], retries);
            assert_eq!(node.get_data()["power_cycle"], u32::from(power_cycle));
        }
    }
}

#[cfg(test)]
mod reset_keepalive_tests {
    use super::ResetKeepalive;

    #[test]
    fn waits_once_after_touch_is_satisfied() {
        let mut keepalive = ResetKeepalive::default();
        assert!(!keepalive.update(0x01));
        assert!(!keepalive.update(0x02));
        assert!(!keepalive.update(0x02));
        assert!(!keepalive.update(0x03));
        assert!(keepalive.update(0x01));
        assert!(!keepalive.update(0x01));
        assert!(!keepalive.update(0x02));
        assert!(!keepalive.update(0x01));
    }
}
