use std::collections::BTreeMap;
use std::sync::OnceLock;
use std::sync::atomic::AtomicBool;

use der::Decode;
use serde_json::{Value, json};

use yubikit::core::Transport;
use yubikit::device::{DeviceError, YubiKeyDevice};
use yubikit::management::{Capability, UsbInterface};
use yubikit::platform::device::get_name;
use yubikit::securitydomain::{KeyRef, SecurityDomainSession};
use yubikit::smartcard::ScpKeyParams;

use ykman::device::{DeviceSource, get_device_source};

use crate::connection::ConnectionNode;
use crate::error::{RpcError, RpcResponse};
use crate::monitor;
use crate::rpc::{RpcNode, SignalFn};
use crate::util::{id_from_fingerprint, version_to_json};

/// Cached process-wide answer to "are we backed by the ykman-svc service?".
///
/// Set the first time a [`DevicesNode`] is constructed (at helper startup).
/// Consulted elsewhere (e.g. [`crate::management::await_reboot`]) so the
/// local [`monitor`] is never started when the service is doing device
/// enumeration instead.
static IS_SERVICE: OnceLock<bool> = OnceLock::new();

type DeviceWithRevision = (Box<dyn YubiKeyDevice>, u64);

/// Whether device access is backed by the ykman-svc service (RPC) rather
/// than direct local access. `false` until the first [`DevicesNode`] has
/// been constructed.
pub fn is_service_mode() -> bool {
    IS_SERVICE.get().copied().unwrap_or(false)
}

pub struct DevicesNode {
    source: Box<dyn DeviceSource>,
    /// Whether `source` is backed by the ykman-svc service (RPC) rather than
    /// direct local device access.
    is_service: bool,
    device_mapping: BTreeMap<String, Box<dyn YubiKeyDevice>>,
    devices: BTreeMap<String, Value>,
    // A monitor change can replace interface paths without changing metadata.
    revisions: BTreeMap<String, u64>,
    // Monitors (including ykman-svc's) do not emit changes for non-rebooting
    // application toggles, so keep the freshly read info until removal.
    refreshed_info: BTreeMap<String, Value>,
    child_invalidated: bool,
}

impl DevicesNode {
    pub fn new() -> Self {
        let source = get_device_source();
        let is_service = source.is_service();
        IS_SERVICE.get_or_init(|| is_service);
        if is_service {
            log::info!("Connected to ykman-svc service for device access");
        }
        Self {
            source,
            is_service,
            device_mapping: BTreeMap::new(),
            devices: BTreeMap::new(),
            revisions: BTreeMap::new(),
            refreshed_info: BTreeMap::new(),
            child_invalidated: false,
        }
    }

    /// Enumerate currently connected devices, using the ykman-svc service
    /// (via RPC) when available, or the local [`monitor`]'s live inventory
    /// otherwise. The monitor runs continuously in the background for the
    /// lifetime of the helper process, so this is always up to date and
    /// never needs to trigger a fresh USB/PC-SC scan.
    fn list_devices(&mut self) -> Result<Vec<DeviceWithRevision>, DeviceError> {
        if self.is_service {
            self.source
                .list_devices()
                .map(|devices| devices.into_iter().map(|device| (device, 0)).collect())
        } else {
            Ok(monitor::devices()
                .into_iter()
                .map(|(device, revision)| (Box::new(device) as Box<dyn YubiKeyDevice>, revision))
                .collect())
        }
    }
}

impl RpcNode for DevicesNode {
    fn get_data(&self) -> Value {
        // Previously exposed a raw USB PID scan ("pids") so the frontend
        // could detect devices the helper couldn't enumerate (e.g. FIDO-only
        // devices without admin on Windows). The device monitor only tracks
        // devices it can successfully read, so this is now always empty, as
        // it already was in service mode.
        json!({"state": 0, "pids": {}})
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["scan"]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let previous = std::mem::take(&mut self.devices);
        let previous_revisions = std::mem::take(&mut self.revisions);
        match self.list_devices() {
            Ok(devs) => {
                self.device_mapping.clear();
                for (dev, revision) in devs {
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
                            "enabled_capabilities": self.refreshed_info.get(&dev_id)
                                .map(|info| info["config"]["enabled_capabilities"].clone())
                                .unwrap_or_else(|| caps_to_json(&dev.info().config.enabled_capabilities)),
                        }),
                    );
                    self.device_mapping.insert(dev_id.clone(), dev);
                    self.revisions.insert(dev_id, revision);
                }
                self.refreshed_info
                    .retain(|id, _| self.device_mapping.contains_key(id));
            }
            Err(e) => {
                log::warn!("Failed to list devices: {e}");
                self.devices.clear();
                self.device_mapping.clear();
                self.refreshed_info.clear();
            }
        }
        if inventory_changed(
            &previous,
            &self.devices,
            &previous_revisions,
            &self.revisions,
        ) {
            self.child_invalidated = true;
        }
        self.devices.clone()
    }

    fn call_action(
        &mut self,
        action: &str,
        _params: &Value,
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

        if !self.device_mapping.contains_key(name) {
            self.list_children();
        }

        let dev = self
            .device_mapping
            .get(name)
            .ok_or_else(|| RpcError::no_such_node(name))?;

        let mut node = DeviceNode::new(dev.as_ref());
        if let Some(info) = self.refreshed_info.get(name) {
            node.set_info(info.clone());
        }
        Ok(Box::new(node))
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(action, "scan")
    }

    fn is_child_valid(&self, name: &str) -> bool {
        if self.child_invalidated {
            return false;
        }
        self.devices.contains_key(name)
    }

    fn close(&mut self) {
        self.device_mapping.clear();
        self.revisions.clear();
    }

    fn handle_child_response(&mut self, response: &mut RpcResponse) {
        if response.flags.iter().any(|f| f == "device_info")
            && let Some(info) = response.body.get("info").filter(|v| !v.is_null())
            && let Some(id) = response.body.get("device_id").and_then(Value::as_str)
            && self.device_mapping.contains_key(id)
        {
            self.refreshed_info.insert(id.to_string(), info.clone());
            if let Some(body) = response.body.as_object_mut() {
                body.remove("device_id");
            }
        }
        if response.flags.iter().any(|f| f == "device_closed") {
            log::debug!("Device closed flag received, invalidating state");
            self.child_invalidated = true;
            self.device_mapping.clear();
            self.devices.clear();
            self.revisions.clear();
            self.refreshed_info.clear();
            response.flags.retain(|f| f != "device_closed");
        }
    }
}

fn inventory_changed(
    previous: &BTreeMap<String, Value>,
    current: &BTreeMap<String, Value>,
    previous_revisions: &BTreeMap<String, u64>,
    current_revisions: &BTreeMap<String, u64>,
) -> bool {
    previous != current || previous_revisions != current_revisions
}

fn fido_open_error(device: &str, error: &DeviceError, is_service: bool) -> RpcError {
    #[cfg(windows)]
    if !is_service && !crate::util::is_admin() {
        return RpcError::with_body(
            "fido-blocked-error",
            "FIDO access required admin",
            json!({ "connection": "fido" }),
        );
    }
    #[cfg(not(windows))]
    let _ = is_service;
    RpcError::connection_error(device, "fido", &format!("{error:?}"))
}

/// A YubiKey device node — works with both local and service-backed devices.
pub struct DeviceNode {
    device: Box<dyn YubiKeyDevice>,
    data: Value,
    refreshed_info: Option<Value>,
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
            refreshed_info: None,
        }
    }

    fn set_info(&mut self, info: Value) {
        self.data["info"] = info.clone();
        self.refreshed_info = Some(info);
    }
}

impl RpcNode for DeviceNode {
    fn get_data(&self) -> Value {
        self.data.clone()
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        // NFC applications use the reader, regardless of the key's USB configuration.
        if self.device.transport() == Transport::Nfc {
            children.insert("ccid".to_string(), json!({}));
            return children;
        }
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
        _params: &Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        Err(RpcError::no_such_action(action))
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let mut info = self.device.info().clone();
        if let Some(ref refreshed) = self.refreshed_info {
            info.config.enabled_capabilities =
                crate::management::parse_capabilities(&refreshed["config"]);
        }
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
                let conn = self
                    .device
                    .open_fido()
                    .map_err(|e| fido_open_error(&self.device.name(), &e, is_service_mode()))?;
                let dev = self.device.clone_box();
                Ok(Box::new(ConnectionNode::new_fido(dev, conn, info)))
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn handle_child_response(&mut self, response: &mut RpcResponse) {
        if response.flags.iter().any(|f| f == "device_info")
            && let Some(info) = response.body.get("info").filter(|v| !v.is_null())
        {
            self.set_info(info.clone());
            response.body["device_id"] = json!(
                self.device
                    .info()
                    .serial
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| id_from_fingerprint(&self.device.name()))
            );
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
        "name": info.name,
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, Mutex};
    use yubikit::core::{Connection, Version};
    use yubikit::device::ReinsertStatus;
    use yubikit::fido::FidoConnection;
    use yubikit::management::DeviceInfo;
    use yubikit::otp::OtpConnection;
    use yubikit::smartcard::{SmartCardConnection, SmartCardError};

    #[derive(Clone)]
    struct ServiceDevice {
        info: DeviceInfo,
        transport: Transport,
        interfaces: UsbInterface,
    }

    impl ServiceDevice {
        fn new(serial: Option<u32>, transport: Transport) -> Self {
            let mut info = DeviceInfo::parse(&[0], Version(5, 2, 6)).unwrap();
            let capabilities = Capability::FIDO2 | Capability::OATH | Capability::PIV;
            info.serial = serial;
            info.config.enabled_capabilities = [
                (Transport::Usb, capabilities),
                (Transport::Nfc, capabilities),
            ]
            .into();
            info.supported_capabilities = info.config.enabled_capabilities.clone();
            Self {
                info,
                transport,
                interfaces: UsbInterface::CCID | UsbInterface::FIDO | UsbInterface::OTP,
            }
        }
    }

    struct Card(Transport);

    impl Connection for Card {
        type Error = SmartCardError;
        fn close(&mut self) {}
    }

    impl SmartCardConnection for Card {
        fn send_and_receive(&mut self, _apdu: &[u8]) -> Result<(Vec<u8>, u16), SmartCardError> {
            panic!("Discovery must not send application APDUs");
        }

        fn transport(&self) -> Transport {
            self.0
        }
    }

    impl YubiKeyDevice for ServiceDevice {
        fn info(&self) -> &DeviceInfo {
            &self.info
        }
        fn transport(&self) -> Transport {
            self.transport
        }
        fn name(&self) -> String {
            get_name(&self.info)
        }
        fn usb_interfaces(&self) -> UsbInterface {
            self.interfaces
        }
        fn open_smartcard(&self) -> Result<Box<dyn SmartCardConnection + Send>, DeviceError> {
            Ok(Box::new(Card(self.transport)))
        }
        fn open_fido(&self) -> Result<Box<dyn FidoConnection + Send>, DeviceError> {
            Err(DeviceError::NoDeviceFound)
        }
        fn open_otp(&self) -> Result<Box<dyn OtpConnection + Send>, DeviceError> {
            Err(DeviceError::NoDeviceFound)
        }
        fn reinsert(
            &mut self,
            _status_cb: &dyn Fn(ReinsertStatus),
            _cancelled: &dyn Fn() -> bool,
        ) -> Result<(), DeviceError> {
            panic!("Discovery must not request reinsertion");
        }
        fn clone_box(&self) -> Box<dyn YubiKeyDevice> {
            Box::new(self.clone())
        }
    }

    struct ServiceSource(Arc<Mutex<Vec<ServiceDevice>>>);

    impl DeviceSource for ServiceSource {
        fn list_devices(&mut self) -> Result<Vec<Box<dyn YubiKeyDevice>>, DeviceError> {
            Ok(self
                .0
                .lock()
                .unwrap()
                .iter()
                .map(|dev| dev.clone_box())
                .collect())
        }
        fn select_fido(
            &mut self,
            _cancel: Option<&dyn Fn() -> bool>,
        ) -> Result<Box<dyn YubiKeyDevice>, DeviceError> {
            panic!("Discovery must not select a device");
        }
        fn is_service(&self) -> bool {
            true
        }
    }

    fn service_node(devices: Arc<Mutex<Vec<ServiceDevice>>>) -> DevicesNode {
        DevicesNode {
            source: Box::new(ServiceSource(devices)),
            is_service: true,
            device_mapping: BTreeMap::new(),
            devices: BTreeMap::new(),
            revisions: BTreeMap::new(),
            refreshed_info: BTreeMap::new(),
            child_invalidated: false,
        }
    }

    #[test]
    fn service_nfc_devices_are_listed_and_expose_smartcard_applications() {
        let devices = Arc::new(Mutex::new(vec![
            ServiceDevice::new(Some(123), Transport::Nfc),
            ServiceDevice::new(Some(456), Transport::Usb),
            ServiceDevice::new(None, Transport::Nfc),
        ]));
        let mut node = service_node(devices);
        let children = node.list_children();
        assert_eq!(children.len(), 3);
        assert_eq!(children["123"]["transport"], "nfc");
        assert_eq!(children["456"]["transport"], "usb");
        assert_eq!(
            children
                .values()
                .filter(|data| data["serial"].is_null())
                .count(),
            1
        );
        assert_eq!(children["123"]["pid"], Value::Null);

        let mut nfc = node.create_child("123").unwrap();
        assert_eq!(nfc.get_data()["transport"], "nfc");
        assert_eq!(nfc.get_data()["info"]["serial"], 123);
        assert_eq!(nfc.list_children().keys().collect::<Vec<_>>(), ["ccid"]);
        let mut ccid = nfc.create_child("ccid").unwrap();
        let applications = ccid.list_children();
        for application in ["oath", "piv", "ctap2"] {
            assert!(applications.contains_key(application));
        }

        let mut usb = node.create_child("456").unwrap();
        assert_eq!(
            usb.list_children().keys().collect::<Vec<_>>(),
            ["ccid", "fido", "otp"]
        );
    }

    #[test]
    fn service_nfc_removal_and_reinsertion_update_inventory() {
        let devices = Arc::new(Mutex::new(vec![ServiceDevice::new(
            Some(123),
            Transport::Nfc,
        )]));
        let mut node = service_node(devices.clone());
        assert_eq!(node.list_children().len(), 1);
        node.create_child("123").unwrap();
        assert!(node.is_child_valid("123"));

        devices.lock().unwrap().clear();
        assert!(node.list_children().is_empty());
        assert!(!node.is_child_valid("123"));
        assert!(node.create_child("123").is_err());

        devices
            .lock()
            .unwrap()
            .push(ServiceDevice::new(Some(123), Transport::Nfc));
        assert_eq!(node.list_children().len(), 1);
        assert_eq!(
            node.create_child("123").unwrap().get_data()["transport"],
            "nfc"
        );
    }

    #[test]
    fn service_nfc_passkeys_use_smartcard_even_without_usb_ccid() {
        let mut device = ServiceDevice::new(Some(789), Transport::Nfc);
        device.interfaces = UsbInterface::FIDO;
        device.info.config.enabled_capabilities = [
            (Transport::Usb, Capability::FIDO2),
            (Transport::Nfc, Capability::FIDO2),
        ]
        .into();
        let mut node = service_node(Arc::new(Mutex::new(vec![device])));
        assert_eq!(node.list_children()["789"]["transport"], "nfc");
        let mut nfc = node.create_child("789").unwrap();
        assert_eq!(nfc.list_children().keys().collect::<Vec<_>>(), ["ccid"]);
        let mut ccid = nfc.create_child("ccid").unwrap();
        assert!(ccid.list_children().contains_key("ctap2"));
    }

    #[test]
    fn monitor_change_invalidates_cached_device_with_same_metadata() {
        let devices = BTreeMap::from([("123".to_string(), json!({"name": "YubiKey"}))]);
        let original = BTreeMap::from([("123".to_string(), 1)]);
        let changed = BTreeMap::from([("123".to_string(), 2)]);

        assert!(!inventory_changed(&devices, &devices, &original, &original));
        assert!(inventory_changed(&devices, &devices, &original, &changed));
    }

    #[test]
    fn service_fido_open_failure_is_retryable() {
        let error = fido_open_error("YubiKey", &DeviceError::NoDeviceFound, true);
        assert_eq!(error.status, "connection-error");
        assert_eq!(error.body["connection"], "fido");
    }
}
