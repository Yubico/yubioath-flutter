use std::collections::BTreeMap;
use std::sync::atomic::AtomicBool;

use serde_json::{Value, json};

use crate::devices::DevicesNode;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub struct RootNode {
    devices: DevicesNode,
}

impl RootNode {
    pub fn new() -> Self {
        Self {
            devices: DevicesNode::new(),
        }
    }
}

impl RpcNode for RootNode {
    fn get_data(&self) -> Value {
        json!({
            "version": VERSION,
        })
    }

    fn list_actions(&self) -> Vec<&'static str> {
        vec!["diagnose", "logging", "qr"]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        children.insert("devices".to_string(), json!({}));
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
            "diagnose" => {
                let report = ykman::diagnostics::run_diagnostics();
                let report_json = serde_json::to_value(&report)
                    .unwrap_or_else(|e| json!({ "error": format!("{e}") }));
                Ok(RpcResponse::new(json!({
                    "diagnostics": [report_json, "End of diagnostics"]
                })))
            }
            "logging" => {
                let level = params
                    .get("level")
                    .and_then(|v| v.as_str())
                    .unwrap_or("WARNING");
                let log_level: ykman::logging::LogLevel =
                    level.parse().unwrap_or(ykman::logging::LogLevel::Warning);
                ykman::logging::set_log_level(log_level);
                Ok(RpcResponse::new(json!({})))
            }
            "qr" => {
                let image = params.get("image").and_then(|v| v.as_str());
                match crate::qr::scan_qr(image) {
                    Ok(result) => Ok(RpcResponse::new(json!({ "result": result }))),
                    Err(e) if e == "invalid-image" => Err(RpcError::new(
                        "invalid-image",
                        "The provided file is not a valid image",
                    )),
                    Err(e) => {
                        log::warn!("QR scan failed: {e}");
                        Ok(RpcResponse::new(json!({ "result": null })))
                    }
                }
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        match name {
            "devices" => Ok(Box::new(std::mem::replace(
                &mut self.devices,
                DevicesNode::new(),
            ))),
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn action_closes_child(&self, action: &str) -> bool {
        // logging and qr don't close children
        !matches!(action, "logging" | "qr")
    }

    fn retains_children(&self) -> bool {
        true
    }
}
