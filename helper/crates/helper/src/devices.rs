use std::collections::BTreeMap;
use std::sync::atomic::AtomicBool;

use der::Decode;
use serde_json::{Value, json};

use yubikit::core::Transport;
use yubikit::device::YubiKeyDevice;
use yubikit::management::{Capability, UsbInterface};
use yubikit::platform::device::{get_name, scan_usb_devices};
use yubikit::securitydomain::{KeyRef, SecurityDomainSession};
use yubikit::smartcard::ScpKeyParams;

use yubikit::device::DeviceSource;

use ykman::device::get_device_source;

use crate::connection::ConnectionNode;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};
use crate::util::{id_from_fingerprint, version_to_json};

/// Internal state for tracking device changes.
enum ListState {
    /// Direct local device access — tracks USB state fingerprint.
    Local { state: u64 },
    /// Connected to the ykman-svc service — no local state tracking needed.
    Service,
}

pub struct DevicesNode {
    source: Box<dyn DeviceSource>,
    list_state: ListState,
    device_mapping: BTreeMap<String, Box<dyn YubiKeyDevice>>,
    devices: BTreeMap<String, Value>,
    child_invalidated: bool,
}

impl DevicesNode {
    pub fn new() -> Self {
        let source = get_device_source();
        let list_state = if source.is_service() {
            log::info!("Connected to ykman-svc service for USB device access");
            ListState::Service
        } else {
            ListState::Local { state: 0 }
        };
        Self {
            source,
            list_state,
            device_mapping: BTreeMap::new(),
            devices: BTreeMap::new(),
            child_invalidated: false,
        }
    }
}

impl RpcNode for DevicesNode {
    fn get_data(&self) -> Value {
        match &self.list_state {
            ListState::Local { .. } => {
                let (pids, state) = scan_usb_devices();
                json!({
                    "state": state as i64,
                    "pids": pids,
                })
            }
            ListState::Service => {
                json!({"state": 0, "pids": {}})
            }
        }
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["scan"]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        match &mut self.list_state {
            ListState::Local { state } => {
                let (_, current_state) = scan_usb_devices();
                if current_state != *state {
                    log::debug!("State changed (was={}, now={current_state})", *state);
                    self.devices.clear();
                    self.device_mapping.clear();

                    match self.source.list_devices() {
                        Ok(devs) => {
                            for dev in devs {
                                let dev_id = if let Some(serial) = dev.info().serial {
                                    serial.to_string()
                                } else {
                                    id_from_fingerprint(&dev.name())
                                };
                                let name = get_name(dev.info());
                                self.devices.insert(
                                    dev_id.clone(),
                                    json!({
                                        "name": name,
                                        "serial": dev.info().serial,
                                        "transport": transport_to_str(dev.transport()),
                                        "pid": dev.pid(),
                                    }),
                                );
                                self.device_mapping.insert(dev_id, dev);
                            }

                            let (pids, _) = scan_usb_devices();
                            let expected: usize = pids.values().sum();
                            let usb_count = self
                                .device_mapping
                                .values()
                                .filter(|d| d.transport() == Transport::Usb)
                                .count();
                            // Check that all CCID-capable devices are accessible
                            let all_ccid_ok = self.device_mapping.values().all(|d| {
                                d.transport() == Transport::Nfc
                                    || !d.usb_interfaces().contains(UsbInterface::CCID)
                                    || d.open_smartcard().is_ok()
                            });
                            if !all_ccid_ok {
                                log::warn!("Not all devices have CCID access");
                                *state = 0;
                            } else {
                                if expected != usb_count {
                                    log::warn!("Not all devices identified");
                                }
                                *state = current_state;
                                log::debug!("State updated: {current_state}");
                            }
                        }
                        Err(e) => {
                            log::warn!("Failed to list devices: {e}");
                        }
                    }
                }
                self.devices.clone()
            }
            ListState::Service => {
                match self.source.list_devices() {
                    Ok(devs) => {
                        self.devices.clear();
                        self.device_mapping.clear();
                        for dev in devs {
                            if dev.transport() == Transport::Nfc {
                                continue;
                            }
                            let dev_id = if let Some(serial) = dev.info().serial {
                                serial.to_string()
                            } else {
                                id_from_fingerprint(&dev.name())
                            };
                            let name = get_name(dev.info());
                            self.devices.insert(
                                dev_id.clone(),
                                json!({
                                    "name": name,
                                    "serial": dev.info().serial,
                                    "transport": transport_to_str(dev.transport()),
                                    "pid": dev.pid(),
                                }),
                            );
                            self.device_mapping.insert(dev_id, dev);
                        }
                    }
                    Err(e) => {
                        log::warn!("Failed to get service devices: {e}");
                    }
                }
                self.devices.clone()
            }
        }
    }

    fn call_action(
        &mut self,
        action: &str,
        _params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "scan" => Ok(RpcResponse::new(self.get_data())),
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        self.child_invalidated = false;

        let needs_refresh = match &self.list_state {
            ListState::Local { state } => !self.device_mapping.contains_key(name) || *state == 0,
            ListState::Service => !self.device_mapping.contains_key(name),
        };
        if needs_refresh {
            self.list_children();
        }

        let dev = self
            .device_mapping
            .get(name)
            .ok_or_else(|| RpcError::no_such_node(name))?;

        Ok(Box::new(DeviceNode::new(dev.as_ref())))
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(action, "scan")
    }

    fn is_child_valid(&self, name: &str) -> bool {
        if self.child_invalidated {
            return false;
        }
        match &self.list_state {
            ListState::Local { state } => *state != 0 && self.device_mapping.contains_key(name),
            ListState::Service => self.devices.contains_key(name),
        }
    }

    fn close(&mut self) {
        if let ListState::Local { state } = &mut self.list_state {
            *state = 0;
        }
        self.device_mapping.clear();
    }

    fn handle_child_response(&mut self, response: &mut RpcResponse) {
        if response.flags.iter().any(|f| f == "device_closed") {
            log::debug!("Device closed flag received, invalidating state");
            self.child_invalidated = true;
            if let ListState::Local { state } = &mut self.list_state {
                *state = 0;
            }
            self.device_mapping.clear();
            self.devices.clear();
            response.flags.retain(|f| f != "device_closed");
        }
    }
}

/// A YubiKey device node — works with both local and service-backed devices.
pub struct DeviceNode {
    device: Box<dyn YubiKeyDevice>,
    data: Value,
}

impl DeviceNode {
    pub fn new(device: &dyn YubiKeyDevice) -> Self {
        let info = device.info();
        let name = get_name(info);
        let transport = device.transport();
        let data = json!({
            "name": name,
            "transport": transport_to_str(transport),
            "pid": device.pid(),
            "info": info_to_json(info),
        });
        Self {
            device: device.clone_box(),
            data,
        }
    }
}

impl RpcNode for DeviceNode {
    fn get_data(&self) -> Value {
        self.data.clone()
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        let ifaces = self.device.usb_interfaces();
        if ifaces.contains(UsbInterface::CCID) {
            children.insert("ccid".to_string(), json!({}));
        }
        if ifaces.contains(UsbInterface::OTP) {
            children.insert("otp".to_string(), json!({}));
        }
        if ifaces.contains(UsbInterface::FIDO) {
            children.insert("fido".to_string(), json!({}));
        }
        children
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
        let info = self.device.info().clone();
        let transport = self.device.transport();
        let is_nfc = transport == Transport::Nfc;
        match name {
            "ccid" => {
                let conn = self.device.open_smartcard().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "ccid", &format!("{e:?}"))
                })?;

                // Negotiate SCP11b for FIPS-capable devices over NFC
                let scp_params = if is_nfc && info.fips_capable != Capability::NONE {
                    negotiate_scp11b(self.device.as_ref())
                } else {
                    None
                };

                let dev = self.device.clone_box();
                Ok(Box::new(ConnectionNode::new_smartcard(
                    dev, conn, info, transport, scp_params,
                )))
            }
            "otp" => {
                let conn = self.device.open_otp().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "otp", &format!("{e:?}"))
                })?;
                let dev = self.device.clone_box();
                Ok(Box::new(ConnectionNode::new_otp(dev, conn, info)))
            }
            "fido" => {
                let conn = self.device.open_fido().map_err(|e| {
                    #[cfg(windows)]
                    if !crate::util::is_admin() {
                        return RpcError::with_body(
                            "fido-blocked-error",
                            "FIDO access required admin",
                            json!({ "connection": "fido" }),
                        );
                    }
                    RpcError::connection_error(&self.device.name(), "fido", &format!("{e:?}"))
                })?;
                let dev = self.device.clone_box();
                Ok(Box::new(ConnectionNode::new_fido(dev, conn, info)))
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }
}

fn transport_to_str(t: Transport) -> &'static str {
    match t {
        Transport::Usb => "usb",
        Transport::Nfc => "nfc",
    }
}

/// Convert DeviceInfo to a JSON value matching Python's asdict() + custom JSON encoder.
/// Enums → integer values, Version → [major, minor, micro], Transport keys → "usb"/"nfc".
pub fn info_to_json(info: &yubikit::management::DeviceInfo) -> Value {
    json!({
        "serial": info.serial,
        "version": version_to_json(&info.version),
        "form_factor": info.form_factor as u8,
        "supported_capabilities": caps_to_json(&info.supported_capabilities),
        "config": {
            "enabled_capabilities": caps_to_json(&info.config.enabled_capabilities),
            "auto_eject_timeout": info.config.auto_eject_timeout,
            "challenge_response_timeout": info.config.challenge_response_timeout,
            "device_flags": info.config.device_flags.map(|f| f.0),
            "nfc_restricted": info.config.nfc_restricted,
        },
        "is_locked": info.is_locked,
        "is_fips": info.is_fips,
        "is_sky": info.is_sky,
        "part_number": info.part_number,
        "fips_capable": info.fips_capable.0,
        "fips_approved": info.fips_approved.0,
        "pin_complexity": info.pin_complexity,
        "reset_blocked": info.reset_blocked.0,
        "fps_version": info.fps_version.as_ref().map(version_to_json),
        "stm_version": info.stm_version.as_ref().map(version_to_json),
        "version_qualifier": {
            "version": version_to_json(&info.version_qualifier.version),
            "type": info.version_qualifier.release_type as u8,
            "iteration": info.version_qualifier.iteration,
        },
    })
}

fn caps_to_json(
    caps: &std::collections::HashMap<Transport, yubikit::management::Capability>,
) -> Value {
    let mut map = serde_json::Map::new();
    for (transport, cap) in caps {
        // Python TRANSPORT is a plain Enum, so dict keys use lowercase name: "usb", "nfc"
        map.insert(transport_to_str(*transport).to_string(), json!(cap.0));
    }
    Value::Object(map)
}

/// Negotiate SCP11b parameters by opening a separate connection to the
/// Security Domain and reading the SCP11b certificate bundle (KID=0x13).
fn negotiate_scp11b(device: &dyn YubiKeyDevice) -> Option<ScpKeyParams> {
    let conn = device.open_smartcard().ok()?;
    let mut sd = SecurityDomainSession::new(conn).ok()?;

    let keys = sd.get_key_information().ok()?;
    let kvn = keys.keys().find(|r| r.kid == 0x13).map(|r| r.kvn)?;

    let key_ref = KeyRef::new(0x13, kvn);
    let certs = sd.get_certificate_bundle(key_ref).ok()?;
    let leaf_cert_der = certs.last()?;

    let pk_bytes = extract_ec_pubkey_from_cert(leaf_cert_der).ok()?;

    Some(ScpKeyParams::Scp11b {
        kid: 0x13,
        kvn,
        pk_sd_ecka: pk_bytes,
    })
}

/// Extract the uncompressed EC public key bytes from a DER-encoded X.509 cert.
fn extract_ec_pubkey_from_cert(cert_der: &[u8]) -> Result<Vec<u8>, &'static str> {
    let cert =
        x509_cert::Certificate::from_der(cert_der).map_err(|_| "Failed to parse certificate")?;
    let spki = &cert.tbs_certificate.subject_public_key_info;
    let pk_bytes = spki
        .subject_public_key
        .as_bytes()
        .ok_or("Empty public key")?;

    if (pk_bytes.len() == 65 && pk_bytes[0] == 0x04)
        || (pk_bytes.len() == 33 && (pk_bytes[0] == 0x02 || pk_bytes[0] == 0x03))
    {
        Ok(pk_bytes.to_vec())
    } else {
        Err("Unexpected public key format")
    }
}
