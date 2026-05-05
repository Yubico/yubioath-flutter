use std::collections::BTreeMap;
use std::sync::atomic::AtomicBool;

use der::Decode;
use serde_json::{Value, json};

use yubikit::core::Transport;
use yubikit::device::{
    LocalYubiKeyDevice, YubiKeyDevice, get_name, list_devices, scan_usb_devices,
};
use yubikit::management::{Capability, UsbInterface};
use yubikit::securitydomain::{KeyRef, SecurityDomainSession};
use yubikit::smartcard::ScpKeyParams;

use ykman::rpc::client::RpcClient;
use ykman::rpc::proxy::RpcDevice;

use crate::connection::ConnectionNode;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};
use crate::util::{id_from_fingerprint, version_to_json};

/// Source of device data — either local enumeration or the ykman-svc service.
enum DeviceSource {
    /// Direct local device access (scan_usb_devices + list_devices).
    Local {
        list_state: u64,
        device_mapping: BTreeMap<String, LocalYubiKeyDevice>,
    },
    /// Connected to the ykman-svc service (pipe/socket).
    Service(RpcClient),
}

pub struct DevicesNode {
    source: DeviceSource,
    devices: BTreeMap<String, Value>,
}

impl DevicesNode {
    pub fn new() -> Self {
        // Try to connect to the service; fall back to local access.
        let source = match RpcClient::connect_pipe() {
            Ok(client) => {
                log::info!("Connected to ykman-svc service for USB device access");
                DeviceSource::Service(client)
            }
            Err(e) => {
                log::debug!(
                    "ykman-svc not available ({}), using direct device access",
                    e.0
                );
                DeviceSource::Local {
                    list_state: 0,
                    device_mapping: BTreeMap::new(),
                }
            }
        };
        Self {
            source,
            devices: BTreeMap::new(),
        }
    }
}

impl RpcNode for DevicesNode {
    fn get_data(&self) -> Value {
        match &self.source {
            DeviceSource::Local { .. } => {
                let (pids, state) = scan_usb_devices();
                json!({
                    "state": state as i64,
                    "pids": pids,
                })
            }
            DeviceSource::Service(_) => {
                // For service mode, state and pid accounting are managed by the service.
                json!({"state": 0, "pids": {}})
            }
        }
    }
    fn list_actions(&self) -> Vec<&'static str> {
        vec!["scan"]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        match &mut self.source {
            DeviceSource::Local {
                list_state,
                device_mapping,
            } => {
                let (_, state) = scan_usb_devices();
                if state != *list_state {
                    log::debug!("State changed (was={}, now={state})", *list_state);
                    self.devices.clear();
                    device_mapping.clear();

                    let interfaces = UsbInterface::CCID | UsbInterface::OTP | UsbInterface::FIDO;
                    match list_devices(interfaces) {
                        Ok(devs) => {
                            for dev in devs {
                                let dev_id = if let Some(serial) = dev.serial() {
                                    serial.to_string()
                                } else if let Some(reader) = dev.reader_name() {
                                    id_from_fingerprint(reader)
                                } else if let Some(path) = dev.hid_path() {
                                    id_from_fingerprint(path)
                                } else if let Some(path) = dev.fido_path() {
                                    id_from_fingerprint(path)
                                } else {
                                    continue;
                                };

                                let name = get_name(dev.info());
                                let transport_str = transport_to_str(dev.transport());
                                self.devices.insert(
                                    dev_id.clone(),
                                    json!({
                                        "pid": dev.pid(),
                                        "name": name,
                                        "serial": dev.serial(),
                                        "transport": transport_str,
                                    }),
                                );
                                device_mapping.insert(dev_id, dev);
                            }

                            let (pids, _) = scan_usb_devices();
                            let expected: usize = pids.values().sum();
                            let usb_count = device_mapping
                                .values()
                                .filter(|d| d.transport() == Transport::Usb)
                                .count();
                            let all_ccid_ok = device_mapping.values().all(|d| {
                                d.transport() == Transport::Nfc
                                    || !d.usb_interfaces().contains(UsbInterface::CCID)
                                    || d.reader_name().is_some()
                            });
                            if expected == usb_count && all_ccid_ok {
                                *list_state = state;
                                log::debug!("State updated: {state}");
                            } else {
                                if !all_ccid_ok {
                                    log::warn!("Not all devices have CCID access");
                                } else {
                                    log::warn!("Not all devices identified");
                                }
                                *list_state = 0;
                            }
                        }
                        Err(e) => {
                            log::warn!("Failed to list devices: {e}");
                        }
                    }
                }
                self.devices.clone()
            }
            DeviceSource::Service(client) => {
                // Ask the service to refresh its device list.
                let _ = client.call("update_children", &[], json!({}), None, false);

                // Get the root node info which includes children.
                let root = match client.get(&[]) {
                    Ok(r) => r,
                    Err(e) => {
                        log::warn!("Failed to get service root: {e}");
                        return self.devices.clone();
                    }
                };

                let children = root
                    .body
                    .get("children")
                    .and_then(|v| v.as_object())
                    .cloned()
                    .unwrap_or_default();

                // Filter to USB-only devices.
                self.devices.clear();
                for (name, info) in children {
                    let transport = info.get("transport").and_then(|v| v.as_str());
                    if transport == Some("nfc") {
                        continue; // Skip NFC devices from the service
                    }
                    let serial = info
                        .get("serial")
                        .and_then(|v| v.as_u64())
                        .map(|s| s as u32);
                    let pid = info.get("pid").and_then(|v| v.as_u64()).map(|p| p as u16);
                    let dev_name = info
                        .get("name")
                        .and_then(|v| v.as_str())
                        .unwrap_or("YubiKey");
                    self.devices.insert(
                        name,
                        json!({
                            "pid": pid,
                            "name": dev_name,
                            "serial": serial,
                            "transport": transport.unwrap_or("usb"),
                        }),
                    );
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
        match &mut self.source {
            DeviceSource::Local {
                list_state,
                device_mapping,
            } => {
                // Refresh if needed
                if !device_mapping.contains_key(name) || *list_state == 0 {
                    self.list_children();
                }
                // Re-borrow after list_children
                let DeviceSource::Local { device_mapping, .. } = &self.source else {
                    unreachable!()
                };

                let dev = device_mapping
                    .get(name)
                    .ok_or_else(|| RpcError::no_such_node(name))?;

                Ok(Box::new(LocalDeviceNode::new(dev.clone())))
            }
            DeviceSource::Service(_) => {
                // Open a new service connection for this device.
                let device = connect_service_device(name)?;
                Ok(Box::new(ServiceDeviceNode::new(device)))
            }
        }
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(action, "scan")
    }

    fn is_child_valid(&self, name: &str) -> bool {
        match &self.source {
            DeviceSource::Local {
                list_state,
                device_mapping,
            } => *list_state != 0 && device_mapping.contains_key(name),
            DeviceSource::Service(_) => self.devices.contains_key(name),
        }
    }

    fn close(&mut self) {
        match &mut self.source {
            DeviceSource::Local {
                list_state,
                device_mapping,
            } => {
                *list_state = 0;
                device_mapping.clear();
            }
            DeviceSource::Service(_) => {}
        }
    }

    fn handle_child_response(&mut self, response: &mut RpcResponse) {
        if response.flags.iter().any(|f| f == "device_closed") {
            log::debug!("Device closed flag received, invalidating state");
            match &mut self.source {
                DeviceSource::Local {
                    list_state,
                    device_mapping,
                } => {
                    *list_state = 0;
                    device_mapping.clear();
                }
                DeviceSource::Service(_) => {
                    self.devices.clear();
                }
            }
            response.flags.retain(|f| f != "device_closed");
        }
    }
}

/// Connect to the service and target a specific device by name.
fn connect_service_device(name: &str) -> Result<RpcDevice, RpcError> {
    let client = RpcClient::connect_pipe()
        .map_err(|e| RpcError::new("connection-error", format!("Service unavailable: {}", e.0)))?;
    RpcDevice::from_client_at(client, name).map_err(|e| {
        RpcError::new(
            "connection-error",
            format!("Failed to open device: {}", e.0),
        )
    })
}

/// A YubiKey device node backed by the ykman-svc service.
///
/// Uses an `RpcDevice` (which proxies all connections through the service)
/// to provide the same interface as `LocalDeviceNode`.
struct ServiceDeviceNode {
    device: RpcDevice,
    data: Value,
}

impl ServiceDeviceNode {
    fn new(device: RpcDevice) -> Self {
        let info = device.info();
        let name = device.name();
        let pid = device.pid();
        // The OTP/CCID applet SELECT response returns version 0.0.1 for dev firmware.
        // patch_version() replaces that with the override, but only if it's been set.
        // In service mode the helper never opens a local device, so we set it here
        // from the real firmware version read from the service.
        yubikit::core::set_override_version(info.version);
        let data = json!({
            "pid": pid,
            "name": name,
            "transport": "usb",
            "info": info_to_json(info),
        });
        Self { device, data }
    }
}

impl RpcNode for ServiceDeviceNode {
    fn get_data(&self) -> Value {
        self.data.clone()
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        // The RpcDevice knows what connections are available from the service.
        if self.device.has_ccid() {
            children.insert("ccid".to_string(), json!({}));
        }
        if self.device.has_otp() {
            children.insert("otp".to_string(), json!({}));
        }
        if self.device.has_ctap() {
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
        match name {
            "ccid" => {
                let conn = self.device.open_smartcard().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "ccid", &format!("{e:?}"))
                })?;
                let dev: Box<dyn YubiKeyDevice> = Box::new(self.device.clone());
                Ok(Box::new(ConnectionNode::new_service_smartcard(
                    dev,
                    conn,
                    info,
                    Transport::Usb,
                )))
            }
            "otp" => {
                let conn = self.device.open_otp().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "otp", &format!("{e:?}"))
                })?;
                let dev: Box<dyn YubiKeyDevice> = Box::new(self.device.clone());
                Ok(Box::new(ConnectionNode::new_service_otp(dev, conn, info)))
            }
            "fido" => {
                let conn = self.device.open_fido().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "fido", &format!("{e:?}"))
                })?;
                let dev: Box<dyn YubiKeyDevice> = Box::new(self.device.clone());
                Ok(Box::new(ConnectionNode::new_service_fido(dev, conn, info)))
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }
}

/// A locally-connected YubiKey device node (USB or NFC, direct access).
pub struct LocalDeviceNode {
    device: LocalYubiKeyDevice,
    data: Option<Value>,
}

impl LocalDeviceNode {
    pub fn new(device: LocalYubiKeyDevice) -> Self {
        let data = Self::read_data(&device);
        Self { device, data }
    }

    fn read_data(dev: &LocalYubiKeyDevice) -> Option<Value> {
        let info = dev.info();
        let name = get_name(info);
        let transport_str = transport_to_str(dev.transport());
        Some(json!({
            "pid": dev.pid(),
            "name": name,
            "transport": transport_str,
            "info": info_to_json(info),
        }))
    }
}

impl RpcNode for LocalDeviceNode {
    fn get_data(&self) -> Value {
        self.data.clone().unwrap_or_else(|| json!(null))
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        let info = self.device.info();
        let _usb_caps = info
            .config
            .enabled_capabilities
            .get(&Transport::Usb)
            .copied();

        if self.device.reader_name().is_some() {
            children.insert("ccid".to_string(), json!({}));
        }
        if self.device.hid_path().is_some() {
            children.insert("otp".to_string(), json!({}));
        }
        if self.device.fido_path().is_some() {
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
        let is_nfc = self.device.transport() == Transport::Nfc;
        match name {
            "ccid" => {
                let conn = self.device.open_smartcard().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "ccid", &format!("{e:?}"))
                })?;

                // Negotiate SCP11b for FIPS-capable devices over NFC
                let scp_params = if is_nfc && info.fips_capable != Capability::NONE {
                    negotiate_scp11b(&self.device)
                } else {
                    None
                };

                let conn: Box<dyn yubikit::smartcard::SmartCardConnection + Send> = Box::new(conn);
                Ok(Box::new(ConnectionNode::new_smartcard(
                    self.device.clone(),
                    conn,
                    info,
                    scp_params,
                )))
            }
            "otp" => {
                let conn = self.device.open_otp().map_err(|e| {
                    RpcError::connection_error(&self.device.name(), "otp", &format!("{e:?}"))
                })?;
                let conn: Box<dyn yubikit::otp::OtpConnection + Send> = Box::new(conn);
                Ok(Box::new(ConnectionNode::new_otp(
                    self.device.clone(),
                    conn,
                    info,
                )))
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
                let conn: Box<dyn yubikit::fido::FidoConnection + Send> = Box::new(conn);
                Ok(Box::new(ConnectionNode::new_fido(
                    self.device.clone(),
                    conn,
                    info,
                )))
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn handle_child_response(&mut self, response: &mut RpcResponse) {
        if response.flags.iter().any(|f| f == "device_info") {
            log::debug!("Device info flag received, refreshing data");
            let old_info = self.device.info().clone();
            if self.device.refresh_info() {
                self.data = Self::read_data(&self.device);
            }
            if *self.device.info() == old_info {
                // No change to DeviceInfo, further propagation not needed.
                response.flags.retain(|f| f != "device_info");
            }
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
