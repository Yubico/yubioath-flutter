use std::sync::atomic::AtomicBool;
use std::thread;
use std::time::Duration;

use serde_json::{Value, json};

use yubikit::core::Transport;
use yubikit::fido::FidoConnection;
use yubikit::management::{
    Capability, DeviceConfig, DeviceFlag, DeviceInfo, ManagementSession, UsbInterface,
};
use yubikit::otp::OtpConnection;
use yubikit::platform::device::list_devices;
use yubikit::smartcard::SmartCardConnection;

use crate::connection::SharedConn;
use crate::devices::info_to_json;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};

/// After a reboot-triggering configure, wait for the device to reappear.
/// Matches the Python `_await_reboot` behavior: poll every 200ms for ~2s.
fn await_reboot(serial: Option<u32>, usb_enabled: Option<Capability>) {
    let interfaces = match usb_enabled {
        Some(cap) => {
            let mut ifaces = UsbInterface(0);
            if cap.contains(Capability::OTP) {
                ifaces = ifaces | UsbInterface::OTP;
            }
            if cap.contains(Capability::FIDO2) || cap.contains(Capability::U2F) {
                ifaces = ifaces | UsbInterface::FIDO;
            }
            if cap.contains(Capability::PIV)
                || cap.contains(Capability::OATH)
                || cap.contains(Capability::OPENPGP)
                || cap.contains(Capability::HSMAUTH)
            {
                ifaces = ifaces | UsbInterface::CCID;
            }
            ifaces
        }
        None => UsbInterface::CCID | UsbInterface::OTP | UsbInterface::FIDO,
    };

    log::debug!("Waiting for device to re-appear (serial={serial:?})...");
    for i in 0..10 {
        thread::sleep(Duration::from_millis(200));
        match list_devices(interfaces) {
            Ok(devs) => {
                if devs.iter().any(|d| d.info().serial == serial) {
                    log::debug!("Device found after {} ms", (i + 1) * 200);
                    return;
                }
            }
            Err(e) => {
                log::debug!("Error listing devices: {e}");
            }
        }
        log::debug!("Not found, sleep...");
    }
    log::warn!("Timed out waiting for device to re-appear");
}

// --- ManagementCcidNode ---

pub struct ManagementCcidNode {
    session: Option<ManagementSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    info: DeviceInfo,
}

impl ManagementCcidNode {
    pub fn new(
        connection: Box<dyn SmartCardConnection + Send>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        info: DeviceInfo,
    ) -> Result<Self, RpcError> {
        match ManagementSession::new(connection) {
            Ok(session) => Ok(Self {
                session: Some(session),
                conn,
                info,
            }),
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }
}

impl RpcNode for ManagementCcidNode {
    fn get_data(&self) -> Value {
        info_to_json(&self.info)
    }

    fn list_actions(&self) -> Vec<&'static str> {
        if let Some(ref session) = self.session {
            let version = session.version();
            if version >= yubikit::core::Version(5, 0, 0) {
                vec!["configure", "device_reset"]
            } else {
                vec!["set_mode"]
            }
        } else {
            vec![]
        }
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let session = self
            .session
            .as_mut()
            .ok_or_else(|| RpcError::new("session-error", "No active session"))?;

        match action {
            "configure" => {
                let reboot = params
                    .get("reboot")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let cur_lock_code = params
                    .get("cur_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());
                let new_lock_code = params
                    .get("new_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());

                let enabled_capabilities = parse_capabilities(&params);
                let auto_eject_timeout = params
                    .get("auto_eject_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u16);
                let challenge_response_timeout = params
                    .get("challenge_response_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u8);
                let device_flags = params
                    .get("device_flags")
                    .and_then(|v| v.as_u64())
                    .map(|v| DeviceFlag(v as u8));

                let config = DeviceConfig {
                    enabled_capabilities,
                    auto_eject_timeout,
                    challenge_response_timeout,
                    device_flags,
                    nfc_restricted: None,
                };

                let has_changes = !config.enabled_capabilities.is_empty()
                    || config.auto_eject_timeout.is_some()
                    || config.challenge_response_timeout.is_some()
                    || config.device_flags.is_some()
                    || cur_lock_code.is_some()
                    || new_lock_code.is_some()
                    || reboot;

                session
                    .write_device_config(
                        &config,
                        reboot,
                        cur_lock_code.as_deref(),
                        new_lock_code.as_deref(),
                    )
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                let mut flags = Vec::new();
                if has_changes {
                    flags.push("device_info");
                }
                if reboot {
                    let serial = self.info.serial;
                    let usb_enabled = config.enabled_capabilities.get(&Transport::Usb).copied();
                    // Drop the session to release the connection before waiting
                    drop(self.session.take());
                    await_reboot(serial, usb_enabled);
                    flags.push("device_closed");
                }
                Ok(RpcResponse::with_flags(json!({}), flags))
            }
            "device_reset" => {
                session
                    .device_reset()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
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

// --- ManagementOtpNode ---

pub struct ManagementOtpNode {
    session: Option<ManagementSession<Box<dyn OtpConnection + Send>>>,
    conn: SharedConn<Box<dyn OtpConnection + Send>>,
    cached_info: Value,
    serial: Option<u32>,
}

impl ManagementOtpNode {
    pub fn new(
        connection: Box<dyn OtpConnection + Send>,
        conn: SharedConn<Box<dyn OtpConnection + Send>>,
    ) -> Result<Self, RpcError> {
        match ManagementSession::new_otp(connection) {
            Ok(mut session) => {
                let (cached_info, serial) = session
                    .read_device_info()
                    .map(|info| (info_to_json(&info), info.serial))
                    .unwrap_or_else(|_| (json!({}), None));
                Ok(Self {
                    session: Some(session),
                    conn,
                    cached_info,
                    serial,
                })
            }
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }
}

impl RpcNode for ManagementOtpNode {
    fn get_data(&self) -> Value {
        self.cached_info.clone()
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["configure"]
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let session = self
            .session
            .as_mut()
            .ok_or_else(|| RpcError::new("session-error", "No active session"))?;
        match action {
            "configure" => {
                let reboot = params
                    .get("reboot")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let cur_lock_code = params
                    .get("cur_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());
                let new_lock_code = params
                    .get("new_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());
                let enabled_capabilities = parse_capabilities(&params);
                let auto_eject_timeout = params
                    .get("auto_eject_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u16);
                let challenge_response_timeout = params
                    .get("challenge_response_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u8);
                let device_flags = params
                    .get("device_flags")
                    .and_then(|v| v.as_u64())
                    .map(|v| DeviceFlag(v as u8));
                let config = DeviceConfig {
                    enabled_capabilities,
                    auto_eject_timeout,
                    challenge_response_timeout,
                    device_flags,
                    nfc_restricted: None,
                };

                let has_changes = !config.enabled_capabilities.is_empty()
                    || config.auto_eject_timeout.is_some()
                    || config.challenge_response_timeout.is_some()
                    || config.device_flags.is_some()
                    || cur_lock_code.is_some()
                    || new_lock_code.is_some()
                    || reboot;

                session
                    .write_device_config(
                        &config,
                        reboot,
                        cur_lock_code.as_deref(),
                        new_lock_code.as_deref(),
                    )
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                let mut flags = Vec::new();
                if has_changes {
                    flags.push("device_info");
                }
                if reboot {
                    let usb_enabled = config.enabled_capabilities.get(&Transport::Usb).copied();
                    drop(self.session.take());
                    await_reboot(self.serial, usb_enabled);
                    flags.push("device_closed");
                }
                Ok(RpcResponse::with_flags(json!({}), flags))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            *self.conn.lock().unwrap() = Some(session.into_connection());
        }
    }
}

// --- ManagementFidoNode ---

pub struct ManagementFidoNode {
    session: Option<ManagementSession<Box<dyn FidoConnection + Send>>>,
    conn: SharedConn<Box<dyn FidoConnection + Send>>,
    cached_info: Value,
    serial: Option<u32>,
}

impl ManagementFidoNode {
    pub fn new(
        connection: Box<dyn FidoConnection + Send>,
        conn: SharedConn<Box<dyn FidoConnection + Send>>,
    ) -> Result<Self, RpcError> {
        match ManagementSession::new_fido(connection) {
            Ok(mut session) => {
                let (cached_info, serial) = session
                    .read_device_info()
                    .map(|info| (info_to_json(&info), info.serial))
                    .unwrap_or_else(|_| (json!({}), None));
                Ok(Self {
                    session: Some(session),
                    conn,
                    cached_info,
                    serial,
                })
            }
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }
}

impl RpcNode for ManagementFidoNode {
    fn get_data(&self) -> Value {
        self.cached_info.clone()
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["configure"]
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let session = self
            .session
            .as_mut()
            .ok_or_else(|| RpcError::new("session-error", "No active session"))?;
        match action {
            "configure" => {
                let reboot = params
                    .get("reboot")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let cur_lock_code = params
                    .get("cur_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());
                let new_lock_code = params
                    .get("new_lock_code")
                    .and_then(|v| v.as_str())
                    .map(|s| hex::decode(s).unwrap_or_default());
                let enabled_capabilities = parse_capabilities(&params);
                let auto_eject_timeout = params
                    .get("auto_eject_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u16);
                let challenge_response_timeout = params
                    .get("challenge_response_timeout")
                    .and_then(|v| v.as_u64())
                    .map(|v| v as u8);
                let device_flags = params
                    .get("device_flags")
                    .and_then(|v| v.as_u64())
                    .map(|v| DeviceFlag(v as u8));
                let config = DeviceConfig {
                    enabled_capabilities,
                    auto_eject_timeout,
                    challenge_response_timeout,
                    device_flags,
                    nfc_restricted: None,
                };

                let has_changes = !config.enabled_capabilities.is_empty()
                    || config.auto_eject_timeout.is_some()
                    || config.challenge_response_timeout.is_some()
                    || config.device_flags.is_some()
                    || cur_lock_code.is_some()
                    || new_lock_code.is_some()
                    || reboot;

                session
                    .write_device_config(
                        &config,
                        reboot,
                        cur_lock_code.as_deref(),
                        new_lock_code.as_deref(),
                    )
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                let mut flags = Vec::new();
                if has_changes {
                    flags.push("device_info");
                }
                if reboot {
                    let usb_enabled = config.enabled_capabilities.get(&Transport::Usb).copied();
                    drop(self.session.take());
                    await_reboot(self.serial, usb_enabled);
                    flags.push("device_closed");
                }
                Ok(RpcResponse::with_flags(json!({}), flags))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            *self.conn.lock().unwrap() = Some(session.into_connection());
        }
    }
}

fn parse_capabilities(params: &Value) -> std::collections::HashMap<Transport, Capability> {
    let mut caps = std::collections::HashMap::new();
    if let Some(obj) = params
        .get("enabled_capabilities")
        .and_then(|v| v.as_object())
    {
        for (key, val) in obj {
            let transport = match key.as_str() {
                "usb" | "1" => Transport::Usb,
                "nfc" | "2" => Transport::Nfc,
                _ => continue,
            };
            if let Some(v) = val.as_u64() {
                caps.insert(transport, Capability(v as u16));
            }
        }
    }
    caps
}
