use std::collections::BTreeMap;
use std::sync::atomic::{AtomicBool, Ordering};

use serde_json::{Value, json};

use yubikit::otp::OtpConnection;
use yubikit::otp::{modhex_decode, modhex_encode};
use yubikit::smartcard::ScpKeyParams;
use yubikit::smartcard::SmartCardConnection;
use yubikit::yubiotp::{AccessCode, ConfigState, HmacKey, Slot, SlotConfiguration, YubiOtpSession};

use crate::connection::SharedConn;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};

// --- YubiOtpCcidNode ---

pub struct YubiOtpCcidNode {
    session: Option<YubiOtpSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
}

impl YubiOtpCcidNode {
    pub fn new(
        connection: Box<dyn SmartCardConnection + Send>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        scp_params: Option<&ScpKeyParams>,
    ) -> Result<Self, RpcError> {
        let result = if let Some(scp) = scp_params {
            YubiOtpSession::new_with_scp(connection, scp)
        } else {
            YubiOtpSession::new(connection)
        };
        match result {
            Ok(session) => Ok(Self {
                session: Some(session),
                conn,
            }),
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }
}

impl RpcNode for YubiOtpCcidNode {
    fn get_data(&self) -> Value {
        if let Some(ref session) = self.session {
            config_state_to_json(session.get_config_state())
        } else {
            json!({})
        }
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec![
            "swap",
            "serial_modhex",
            "generate_static",
            "keyboard_layouts",
            "format_yubiotp_csv",
        ]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        children.insert("one".to_string(), json!({}));
        children.insert("two".to_string(), json!({}));
        children
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "swap" => {
                let session = self.session.as_mut().unwrap();
                session
                    .swap_slots()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(json!({})))
            }
            "serial_modhex" | "generate_static" | "keyboard_layouts" | "format_yubiotp_csv" => {
                handle_utility_action(action, &params)
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(
            action,
            "serial_modhex" | "generate_static" | "keyboard_layouts" | "format_yubiotp_csv"
        )
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let slot = match name {
            "one" => Slot::One,
            "two" => Slot::Two,
            _ => return Err(RpcError::no_such_node(name)),
        };
        // Re-acquire session from shared conn if needed
        if self.session.is_none()
            && let Some(conn) = self.conn.lock().unwrap().take()
        {
            match YubiOtpSession::new(conn) {
                Ok(session) => self.session = Some(session),
                Err((e, c)) => {
                    *self.conn.lock().unwrap() = Some(c);
                    return Err(RpcError::new("session-error", format!("{e}")));
                }
            }
        }
        let session = self
            .session
            .take()
            .ok_or_else(|| RpcError::new("session-error", "No active YubiOTP session"))?;
        Ok(Box::new(OtpCcidSlotNode::new(
            session,
            self.conn.clone(),
            slot,
        )))
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

// --- YubiOtpOtpNode ---

pub struct YubiOtpOtpNode {
    session: Option<YubiOtpSession<Box<dyn OtpConnection + Send>>>,
    conn: SharedConn<Box<dyn OtpConnection + Send>>,
}

impl YubiOtpOtpNode {
    pub fn new(
        connection: Box<dyn OtpConnection + Send>,
        conn: SharedConn<Box<dyn OtpConnection + Send>>,
    ) -> Result<Self, RpcError> {
        match YubiOtpSession::new_otp(connection) {
            Ok(session) => Ok(Self {
                session: Some(session),
                conn,
            }),
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }
}

impl RpcNode for YubiOtpOtpNode {
    fn get_data(&self) -> Value {
        if let Some(ref session) = self.session {
            config_state_to_json(session.get_config_state())
        } else {
            json!({})
        }
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec![
            "swap",
            "serial_modhex",
            "generate_static",
            "keyboard_layouts",
            "format_yubiotp_csv",
        ]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        children.insert("one".to_string(), json!({}));
        children.insert("two".to_string(), json!({}));
        children
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "swap" => {
                let session = self.session.as_mut().unwrap();
                session
                    .swap_slots()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(json!({})))
            }
            "serial_modhex" | "generate_static" | "keyboard_layouts" | "format_yubiotp_csv" => {
                handle_utility_action(action, &params)
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(
            action,
            "serial_modhex" | "generate_static" | "keyboard_layouts" | "format_yubiotp_csv"
        )
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let slot = match name {
            "one" => Slot::One,
            "two" => Slot::Two,
            _ => return Err(RpcError::no_such_node(name)),
        };
        // Re-acquire session from shared conn if needed
        if self.session.is_none()
            && let Some(conn) = self.conn.lock().unwrap().take()
        {
            match YubiOtpSession::new_otp(conn) {
                Ok(session) => self.session = Some(session),
                Err((e, c)) => {
                    *self.conn.lock().unwrap() = Some(c);
                    return Err(RpcError::new("session-error", format!("{e}")));
                }
            }
        }
        let session = self
            .session
            .take()
            .ok_or_else(|| RpcError::new("session-error", "No active YubiOTP session"))?;
        Ok(Box::new(OtpOtpSlotNode::new(
            session,
            self.conn.clone(),
            slot,
        )))
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

// --- OtpCcidSlotNode (CCID transport) ---

struct OtpCcidSlotNode {
    session: Option<YubiOtpSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    slot: Slot,
    is_configured: bool,
    is_touch_triggered: bool,
}

impl OtpCcidSlotNode {
    fn new(
        session: YubiOtpSession<Box<dyn SmartCardConnection + Send>>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        slot: Slot,
    ) -> Self {
        let state = session.get_config_state();
        let is_configured = state.is_configured(slot).unwrap_or(false);
        let is_touch_triggered = state.is_touch_triggered(slot).unwrap_or(false);
        Self {
            session: Some(session),
            conn,
            slot,
            is_configured,
            is_touch_triggered,
        }
    }
}

impl RpcNode for OtpCcidSlotNode {
    fn get_data(&self) -> Value {
        json!({
            "is_configured": self.is_configured,
            "is_touch_triggered": self.is_touch_triggered,
        })
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = vec!["put"];
        if self.is_configured {
            actions.push("delete");
            actions.push("update");
            if !self.is_touch_triggered {
                actions.push("calculate");
            }
        }
        actions
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let session = self.session.as_mut().unwrap();
        match action {
            "delete" => {
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;
                session
                    .delete_slot(self.slot, cur_acc_code.as_ref())
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            "calculate" => {
                let challenge = params
                    .get("challenge")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing challenge"))?;
                let challenge_bytes = hex::decode(challenge)
                    .map_err(|_| RpcError::invalid_params("Invalid hex challenge"))?;
                let response = session
                    .calculate_hmac_sha1(self.slot, &challenge_bytes)
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(
                    json!({ "response": hex::encode(response) }),
                ))
            }
            "put" => {
                let cfg_type = params
                    .get("type")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing type"))?;
                let options = params.get("options").cloned().unwrap_or_else(|| json!({}));
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;

                let mut config = build_config(cfg_type, &params)?;
                config = apply_options(config, &options)?;

                session
                    .put_configuration(
                        self.slot,
                        &config,
                        cur_acc_code.as_ref(),
                        cur_acc_code.as_ref(),
                    )
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            "update" => {
                let options = params.clone();
                let acc_code = get_acc_code(&params, "acc_code")?;
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;

                let mut config = SlotConfiguration::update();
                config = apply_options(config, &options)?;

                session
                    .update_configuration(
                        self.slot,
                        &config,
                        acc_code.as_ref(),
                        cur_acc_code.as_ref(),
                    )
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

// --- OtpOtpSlotNode (OTP HID transport) ---

struct OtpOtpSlotNode {
    session: Option<YubiOtpSession<Box<dyn OtpConnection + Send>>>,
    conn: SharedConn<Box<dyn OtpConnection + Send>>,
    slot: Slot,
    is_configured: bool,
    is_touch_triggered: bool,
}

impl OtpOtpSlotNode {
    fn new(
        session: YubiOtpSession<Box<dyn OtpConnection + Send>>,
        conn: SharedConn<Box<dyn OtpConnection + Send>>,
        slot: Slot,
    ) -> Self {
        let state = session.get_config_state();
        let is_configured = state.is_configured(slot).unwrap_or(false);
        let is_touch_triggered = state.is_touch_triggered(slot).unwrap_or(false);
        Self {
            session: Some(session),
            conn,
            slot,
            is_configured,
            is_touch_triggered,
        }
    }
}

impl RpcNode for OtpOtpSlotNode {
    fn get_data(&self) -> Value {
        json!({
            "is_configured": self.is_configured,
            "is_touch_triggered": self.is_touch_triggered,
        })
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = vec!["put"];
        if self.is_configured {
            actions.push("delete");
            actions.push("update");
            if !self.is_touch_triggered {
                actions.push("calculate");
            }
        }
        actions
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let session = self.session.as_mut().unwrap();
        match action {
            "delete" => {
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;
                session
                    .delete_slot(self.slot, cur_acc_code.as_ref())
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            "calculate" => {
                let challenge = params
                    .get("challenge")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing challenge"))?;
                let challenge_bytes = hex::decode(challenge)
                    .map_err(|_| RpcError::invalid_params("Invalid hex challenge"))?;
                let is_cancelled = || cancel.load(Ordering::Relaxed);
                let response = session
                    .calculate_hmac_sha1_with_cancel(
                        self.slot,
                        &challenge_bytes,
                        Some(&is_cancelled),
                        None,
                    )
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(
                    json!({ "response": hex::encode(response) }),
                ))
            }
            "put" => {
                let cfg_type = params
                    .get("type")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing type"))?;
                let options = params.get("options").cloned().unwrap_or_else(|| json!({}));
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;

                let mut config = build_config(cfg_type, &params)?;
                config = apply_options(config, &options)?;

                session
                    .put_configuration(
                        self.slot,
                        &config,
                        cur_acc_code.as_ref(),
                        cur_acc_code.as_ref(),
                    )
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            "update" => {
                let options = params.clone();
                let acc_code = get_acc_code(&params, "acc_code")?;
                let cur_acc_code = get_acc_code(&params, "curr_acc_code")?;

                let mut config = SlotConfiguration::update();
                config = apply_options(config, &options)?;

                session
                    .update_configuration(
                        self.slot,
                        &config,
                        acc_code.as_ref(),
                        cur_acc_code.as_ref(),
                    )
                    .map_err(otp_error)?;
                Ok(RpcResponse::new(json!({})))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

// --- Utility actions (closes_child=false in Python) ---

fn handle_utility_action(action: &str, params: &Value) -> Result<RpcResponse, RpcError> {
    match action {
        "serial_modhex" => {
            let serial = params
                .get("serial")
                .and_then(|v| v.as_u64())
                .ok_or_else(|| RpcError::invalid_params("Missing serial"))?
                as u32;
            let mut bytes = vec![0xFF, 0x00];
            bytes.extend_from_slice(&serial.to_be_bytes());
            let encoded = modhex_encode(&bytes);
            Ok(RpcResponse::new(json!({ "encoded": encoded })))
        }
        "format_yubiotp_csv" => {
            let serial = params
                .get("serial")
                .and_then(|v| v.as_u64())
                .ok_or_else(|| RpcError::invalid_params("Missing serial"))?
                as u32;
            let public_id = params
                .get("public_id")
                .and_then(|v| v.as_str())
                .ok_or_else(|| RpcError::invalid_params("Missing public_id"))?;
            let private_id_hex = params
                .get("private_id")
                .and_then(|v| v.as_str())
                .ok_or_else(|| RpcError::invalid_params("Missing private_id"))?;
            let private_id = hex::decode(private_id_hex)
                .map_err(|_| RpcError::invalid_params("Invalid hex private_id"))?;
            let key_hex = params
                .get("key")
                .and_then(|v| v.as_str())
                .ok_or_else(|| RpcError::invalid_params("Missing key"))?;
            let key =
                hex::decode(key_hex).map_err(|_| RpcError::invalid_params("Invalid hex key"))?;

            // public_id comes as modhex string, decode and re-encode
            let public_id_bytes = modhex_decode(public_id)
                .map_err(|_| RpcError::invalid_params("Invalid modhex public_id"))?;
            let public_id_modhex = modhex_encode(&public_id_bytes);

            let ts = chrono::Local::now().format("%Y-%m-%dT%H:%M:%S").to_string();
            let csv = format!(
                "{},{},{},{},{},{},",
                serial,
                public_id_modhex,
                hex::encode(&private_id),
                hex::encode(&key),
                "", // access_code (not provided)
                ts,
            );
            Ok(RpcResponse::new(json!({ "csv": csv })))
        }
        "keyboard_layouts" => {
            use ykman::keyboard::{self, KeyboardLayout};
            let mut result = serde_json::Map::new();
            for &layout in KeyboardLayout::ALL {
                let map = keyboard::scancodes(layout);
                let mut chars: Vec<char> = map.keys().copied().collect();
                chars.sort();
                let char_strings: Vec<Value> = chars
                    .into_iter()
                    .map(|c| Value::String(c.to_string()))
                    .collect();
                result.insert(layout.name().to_string(), Value::Array(char_strings));
            }
            Ok(RpcResponse::new(Value::Object(result)))
        }
        "generate_static" => {
            use ykman::keyboard::{self, KeyboardLayout, MODHEX_CHARS};
            let length = params
                .get("length")
                .and_then(|v| v.as_u64())
                .ok_or_else(|| RpcError::invalid_params("Missing length"))?
                as usize;
            let layout_name = params
                .get("layout")
                .and_then(|v| v.as_str())
                .unwrap_or("MODHEX");
            let layout: KeyboardLayout = layout_name
                .parse()
                .map_err(|e: String| RpcError::invalid_params(e))?;
            let chars: Vec<char> = if layout == KeyboardLayout::Modhex {
                MODHEX_CHARS.chars().collect()
            } else {
                keyboard::scancodes(layout)
                    .keys()
                    .copied()
                    .filter(|c| !"\t\n ".contains(*c))
                    .collect()
            };
            let mut rand_bytes = vec![0u8; length];
            getrandom::fill(&mut rand_bytes)
                .map_err(|e| RpcError::new("rng-error", format!("{e}")))?;
            let password: String = rand_bytes
                .iter()
                .map(|&b| chars[b as usize % chars.len()])
                .collect();
            Ok(RpcResponse::new(json!({ "password": password })))
        }
        _ => Err(RpcError::no_such_action(action)),
    }
}

// --- Shared helpers ---

fn config_state_to_json(state: ConfigState) -> Value {
    let mut data = json!({});
    if let Ok(configured) = state.is_configured(Slot::One) {
        data["slot1_configured"] = json!(configured);
    }
    if let Ok(configured) = state.is_configured(Slot::Two) {
        data["slot2_configured"] = json!(configured);
    }
    if let Ok(triggered) = state.is_touch_triggered(Slot::One) {
        data["slot1_touch_triggered"] = json!(triggered);
    }
    if let Ok(triggered) = state.is_touch_triggered(Slot::Two) {
        data["slot2_touch_triggered"] = json!(triggered);
    }
    data["is_led_inverted"] = json!(state.is_led_inverted());
    data
}

fn otp_error(e: impl std::fmt::Display) -> RpcError {
    RpcError::new("device-error", format!("{e}"))
}

fn get_acc_code(params: &Value, key: &str) -> Result<Option<AccessCode>, RpcError> {
    match params.get(key) {
        Some(v) if !v.is_null() => {
            let hex_str = v
                .as_str()
                .ok_or_else(|| RpcError::invalid_params(format!("{key} must be a hex string")))?;
            let bytes = hex::decode(hex_str)
                .map_err(|_| RpcError::invalid_params(format!("Invalid hex for {key}")))?;
            let code = AccessCode::new(&bytes)
                .map_err(|e| RpcError::invalid_params(format!("Invalid access code: {e}")))?;
            Ok(Some(code))
        }
        _ => Ok(None),
    }
}

fn decode_bytes_param(params: &Value, key: &str) -> Result<Vec<u8>, RpcError> {
    let hex_str = params
        .get(key)
        .and_then(|v| v.as_str())
        .ok_or_else(|| RpcError::invalid_params(format!("Missing {key}")))?;
    hex::decode(hex_str).map_err(|_| RpcError::invalid_params(format!("Invalid hex for {key}")))
}

fn build_config(cfg_type: &str, params: &Value) -> Result<SlotConfiguration, RpcError> {
    match cfg_type {
        "hmac_sha1" => {
            let key_bytes = decode_bytes_param(params, "key")?;
            let key =
                HmacKey::new(&key_bytes).map_err(|e| RpcError::invalid_params(format!("{e}")))?;
            SlotConfiguration::hmac_sha1(&key).map_err(|e| RpcError::invalid_params(format!("{e}")))
        }
        "hotp" => {
            let key_str = params
                .get("key")
                .and_then(|v| v.as_str())
                .ok_or_else(|| RpcError::invalid_params("Missing key"))?;
            // key comes as base32 for HOTP
            let key_bytes = base32::decode(base32::Alphabet::Rfc4648 { padding: false }, key_str)
                .ok_or_else(|| RpcError::invalid_params("Invalid base32 key"))?;
            let key =
                HmacKey::new(&key_bytes).map_err(|e| RpcError::invalid_params(format!("{e}")))?;
            SlotConfiguration::hotp(&key).map_err(|e| RpcError::invalid_params(format!("{e}")))
        }
        "static_password" => {
            let scan_codes =
                if let Some(scan_codes_hex) = params.get("scan_codes").and_then(|v| v.as_str()) {
                    hex::decode(scan_codes_hex)
                        .map_err(|_| RpcError::invalid_params("Invalid hex scan_codes"))?
                } else {
                    let password = params
                        .get("password")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| RpcError::invalid_params("Missing password"))?;
                    let layout_name = params
                        .get("keyboard_layout")
                        .and_then(|v| v.as_str())
                        .unwrap_or("MODHEX");
                    let layout: ykman::keyboard::KeyboardLayout = layout_name
                        .parse()
                        .map_err(|e: String| RpcError::invalid_params(e))?;
                    let map = ykman::keyboard::scancodes(layout);
                    password
                        .chars()
                        .map(|c| {
                            map.get(&c).copied().ok_or_else(|| {
                                RpcError::invalid_params(format!("Unsupported character: {c}"))
                            })
                        })
                        .collect::<Result<Vec<u8>, _>>()?
                };
            SlotConfiguration::static_password(&scan_codes)
                .map_err(|e| RpcError::invalid_params(format!("{e}")))
        }
        "yubiotp" => {
            let public_id = decode_bytes_param(params, "public_id")?;
            let private_id = decode_bytes_param(params, "private_id")?;
            let key = decode_bytes_param(params, "key")?;
            let uid: [u8; 6] = private_id
                .try_into()
                .map_err(|_| RpcError::invalid_params("private_id must be 6 bytes"))?;
            let key_arr: [u8; 16] = key
                .try_into()
                .map_err(|_| RpcError::invalid_params("key must be 16 bytes"))?;
            SlotConfiguration::yubiotp(&public_id, &uid, &key_arr)
                .map_err(|e| RpcError::invalid_params(format!("{e}")))
        }
        other => Err(RpcError::invalid_params(format!(
            "Unsupported configuration type: {other}"
        ))),
    }
}

fn apply_options(
    mut config: SlotConfiguration,
    options: &Value,
) -> Result<SlotConfiguration, RpcError> {
    if let Some(v) = options.get("serial_api_visible").and_then(|v| v.as_bool()) {
        config = config.serial_api_visible(v);
    }
    if let Some(v) = options.get("serial_usb_visible").and_then(|v| v.as_bool()) {
        config = config.serial_usb_visible(v);
    }
    if let Some(v) = options.get("allow_update").and_then(|v| v.as_bool()) {
        config = config.allow_update(v);
    }
    if let Some(v) = options.get("dormant").and_then(|v| v.as_bool()) {
        config = config.dormant(v);
    }
    if let Some(v) = options.get("invert_led").and_then(|v| v.as_bool()) {
        config = config.invert_led(v);
    }
    if let Some(v) = options.get("protect_slot2").and_then(|v| v.as_bool()) {
        config = config
            .protect_slot2(v)
            .map_err(|e| RpcError::invalid_params(format!("{e}")))?;
    }
    if let Some(v) = options.get("require_touch").and_then(|v| v.as_bool()) {
        config = config.require_touch(v);
    }
    if let Some(v) = options.get("lt64").and_then(|v| v.as_bool()) {
        config = config.lt64(v);
    }
    if let Some(v) = options.get("append_cr").and_then(|v| v.as_bool()) {
        config = config.append_cr(v);
    }
    if let Some(v) = options.get("use_numeric").and_then(|v| v.as_bool()) {
        config = config.use_numeric(v);
    }
    if let Some(v) = options.get("fast_trigger").and_then(|v| v.as_bool()) {
        config = config.fast_trigger(v);
    }
    if let Some(v) = options.get("digits8").and_then(|v| v.as_bool()) {
        config = config.digits8(v);
    }
    if let Some(v) = options.get("send_reference").and_then(|v| v.as_bool()) {
        config = config.send_reference(v);
    }
    if let Some(v) = options.get("short_ticket").and_then(|v| v.as_bool()) {
        config = config.short_ticket(v);
    }
    if let Some(v) = options.get("manual_update").and_then(|v| v.as_bool()) {
        config = config.manual_update(v);
    }
    if let Some(imf) = options.get("imf").and_then(|v| v.as_u64()) {
        config = config
            .imf(imf as u32)
            .map_err(|e| RpcError::invalid_params(format!("{e}")))?;
    }
    if let Some(tabs) = options.get("tabs").and_then(|v| v.as_array())
        && tabs.len() == 3
    {
        config = config.tabs(
            tabs[0].as_bool().unwrap_or(false),
            tabs[1].as_bool().unwrap_or(false),
            tabs[2].as_bool().unwrap_or(false),
        );
    }
    if let Some(delay) = options.get("delay").and_then(|v| v.as_array())
        && delay.len() == 2
    {
        config = config.delay(
            delay[0].as_bool().unwrap_or(false),
            delay[1].as_bool().unwrap_or(false),
        );
    }
    if let Some(pacing) = options.get("pacing").and_then(|v| v.as_array())
        && pacing.len() == 2
    {
        config = config.pacing(
            pacing[0].as_bool().unwrap_or(false),
            pacing[1].as_bool().unwrap_or(false),
        );
    }
    if let Some(sp) = options.get("strong_password").and_then(|v| v.as_array())
        && sp.len() == 3
    {
        config = config.strong_password(
            sp[0].as_bool().unwrap_or(false),
            sp[1].as_bool().unwrap_or(false),
            sp[2].as_bool().unwrap_or(false),
        );
    }
    if let Some(tid) = options.get("token_id").and_then(|v| v.as_array())
        && !tid.is_empty()
    {
        let token_id_hex = tid[0].as_str().unwrap_or("");
        let token_id_bytes = hex::decode(token_id_hex)
            .map_err(|_| RpcError::invalid_params("Invalid token_id hex"))?;
        let fixed_modhex1 = tid.get(1).and_then(|v| v.as_bool()).unwrap_or(false);
        let fixed_modhex2 = tid.get(2).and_then(|v| v.as_bool()).unwrap_or(false);
        config = config
            .token_id(&token_id_bytes, fixed_modhex1, fixed_modhex2)
            .map_err(|e| RpcError::invalid_params(format!("{e}")))?;
    }
    Ok(config)
}
