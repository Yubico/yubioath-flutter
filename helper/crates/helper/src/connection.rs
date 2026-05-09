use std::collections::BTreeMap;
use std::sync::atomic::AtomicBool;
use std::sync::{Arc, Mutex};

use serde_json::{Value, json};

use yubikit::core::{Connection, Transport};
use yubikit::device::YubiKeyDevice;
use yubikit::fido::FidoConnection;
use yubikit::management::{Capability, DeviceInfo};
use yubikit::otp::OtpConnection;
use yubikit::smartcard::ScpKeyParams;
use yubikit::smartcard::SmartCardConnection;

use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};
use crate::util::version_to_json;

/// Connection shared between ConnectionNode and its session children.
/// When a child session is created, it takes the connection out.
/// When the child is closed, it puts it back.
pub type SharedConn<T> = Arc<Mutex<Option<T>>>;

/// Connection node wrapping a SmartCard connection.
pub struct ConnectionNode {
    conn_type: ConnType,
    transport: Transport,
    info: DeviceInfo,
    device: Option<Box<dyn YubiKeyDevice>>,
    scp_params: Option<ScpKeyParams>,
}

enum ConnType {
    SmartCard(SharedConn<Box<dyn SmartCardConnection + Send>>),
    Otp(SharedConn<Box<dyn OtpConnection + Send>>),
    Fido(SharedConn<Box<dyn FidoConnection + Send>>),
}

impl ConnectionNode {
    pub fn new_smartcard(
        device: Box<dyn YubiKeyDevice>,
        conn: Box<dyn SmartCardConnection + Send>,
        info: DeviceInfo,
        transport: Transport,
        scp_params: Option<ScpKeyParams>,
    ) -> Self {
        Self {
            conn_type: ConnType::SmartCard(Arc::new(Mutex::new(Some(conn)))),
            transport,
            info,
            device: Some(device),
            scp_params,
        }
    }

    pub fn new_otp(
        device: Box<dyn YubiKeyDevice>,
        conn: Box<dyn OtpConnection + Send>,
        info: DeviceInfo,
    ) -> Self {
        Self {
            conn_type: ConnType::Otp(Arc::new(Mutex::new(Some(conn)))),
            transport: Transport::Usb,
            info,
            device: Some(device),
            scp_params: None,
        }
    }

    pub fn new_fido(
        device: Box<dyn YubiKeyDevice>,
        conn: Box<dyn FidoConnection + Send>,
        info: DeviceInfo,
    ) -> Self {
        Self {
            conn_type: ConnType::Fido(Arc::new(Mutex::new(Some(conn)))),
            transport: Transport::Usb,
            info,
            device: Some(device),
            scp_params: None,
        }
    }

    /// Get SCP params for a given capability, if applicable.
    fn scp_params_for(&self, capability: Capability) -> Option<&ScpKeyParams> {
        if self.info.fips_capable.contains(capability) {
            self.scp_params.as_ref()
        } else {
            None
        }
    }

    fn capabilities(&self) -> Capability {
        self.info
            .config
            .enabled_capabilities
            .get(&self.transport)
            .copied()
            .unwrap_or(Capability::NONE)
    }

    fn is_smartcard(&self) -> bool {
        matches!(self.conn_type, ConnType::SmartCard(_))
    }

    fn is_fido(&self) -> bool {
        matches!(self.conn_type, ConnType::Fido(_))
    }

    fn is_otp(&self) -> bool {
        matches!(self.conn_type, ConnType::Otp(_))
    }
}

impl RpcNode for ConnectionNode {
    fn get_data(&self) -> Value {
        json!({
            "version": version_to_json(&self.info.version),
            "serial": self.info.serial,
        })
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        let caps = self.capabilities();

        // management: USB or SmartCard
        if self.transport == Transport::Usb || self.is_smartcard() {
            children.insert("management".to_string(), json!({}));
        }

        // oath: SmartCard + OATH capability
        if self.is_smartcard() && caps.contains(Capability::OATH) {
            children.insert("oath".to_string(), json!({}));
        }

        // piv: SmartCard + PIV capability
        if self.is_smartcard() && caps.contains(Capability::PIV) {
            children.insert("piv".to_string(), json!({}));
        }

        // ctap2: FidoConnection with FIDO2, or SmartCard with FIDO2 over NFC or FIDOCCID
        if (self.is_fido() && caps.contains(Capability::FIDO2))
            || (self.is_smartcard()
                && (caps.contains(Capability::FIDOCCID)
                    || (self.transport == Transport::Nfc && caps.contains(Capability::FIDO2))))
        {
            children.insert("ctap2".to_string(), json!({}));
        }

        // yubiotp: OTP capability and (OtpConnection or SmartCard with NFC/5.3+)
        if caps.contains(Capability::OTP)
            && (self.is_otp()
                || (self.is_smartcard()
                    && (self.transport == Transport::Nfc
                        || self.info.version >= yubikit::core::Version(5, 3, 0)
                        || self.info.version.0 == 3)))
        {
            children.insert("yubiotp".to_string(), json!({}));
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
        match name {
            "management" => {
                match &self.conn_type {
                    ConnType::SmartCard(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::management::ManagementCcidNode::new(
                            c,
                            conn.clone(),
                            self.info.clone(),
                        )?))
                    }
                    ConnType::Otp(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::management::ManagementOtpNode::new(
                            c,
                            conn.clone(),
                        )?))
                    }
                    ConnType::Fido(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::management::ManagementFidoNode::new(
                            c,
                            conn.clone(),
                        )?))
                    }
                }
            }
            "oath" => match &self.conn_type {
                ConnType::SmartCard(conn) => {
                    let c =
                        conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                    let scp = self.scp_params_for(Capability::OATH);
                    Ok(Box::new(crate::oath::OathNode::new(c, conn.clone(), scp)?))
                }
                _ => Err(RpcError::no_such_node(name)),
            },
            "piv" => match &self.conn_type {
                ConnType::SmartCard(conn) => {
                    let c =
                        conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                    let scp = self.scp_params_for(Capability::PIV);
                    Ok(Box::new(crate::piv::PivNode::new(c, conn.clone(), scp)?))
                }
                _ => Err(RpcError::no_such_node(name)),
            },
            "ctap2" => {
                match &self.conn_type {
                    ConnType::Fido(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::fido::Ctap2Node::new_hid(
                            c,
                            conn.clone(),
                            self.device.take(),
                        )?))
                    }
                    ConnType::SmartCard(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::fido::Ctap2Node::new_smartcard(
                            c,
                            conn.clone(),
                            self.device.take(),
                        )?))
                    }
                    _ => Err(RpcError::no_such_node(name)),
                }
            }
            "yubiotp" => {
                match &self.conn_type {
                    ConnType::SmartCard(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        let scp = self.scp_params_for(Capability::OTP);
                        Ok(Box::new(crate::yubiotp::YubiOtpCcidNode::new(
                            c,
                            conn.clone(),
                            scp,
                        )?))
                    }
                    ConnType::Otp(conn) => {
                        let c = conn.lock().unwrap().take().ok_or_else(|| {
                            RpcError::new("connection-error", "Connection in use")
                        })?;
                        Ok(Box::new(crate::yubiotp::YubiOtpOtpNode::new(
                            c,
                            conn.clone(),
                        )?))
                    }
                    _ => Err(RpcError::no_such_node(name)),
                }
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn close(&mut self) {
        // Close the underlying connection by dropping it
        match &self.conn_type {
            ConnType::SmartCard(conn) => {
                let mut guard = conn.lock().unwrap();
                if let Some(mut c) = guard.take() {
                    c.close();
                }
            }
            ConnType::Otp(conn) => {
                let _ = conn.lock().unwrap().take();
            }
            ConnType::Fido(conn) => {
                let _ = conn.lock().unwrap().take();
            }
        }
    }
}
