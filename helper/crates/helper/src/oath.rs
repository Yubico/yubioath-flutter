use std::collections::BTreeMap;
use std::sync::atomic::AtomicBool;

use serde_json::{Value, json};

use yubikit::oath::{
    Code, Credential, CredentialData, HashAlgorithm, OathAccessKey, OathSession, OathType,
};
use yubikit::smartcard::ScpKeyParams;
use yubikit::smartcard::SmartCardConnection;

use crate::appdata::AppData;
use crate::connection::SharedConn;
use crate::error::{RpcError, RpcResponse, SecretStore};
use crate::rpc::{RpcNode, SignalFn};
use crate::util::version_to_json;

use std::sync::Mutex as StdMutex;

static OATH_STATE: std::sync::LazyLock<StdMutex<OathGlobalState>> =
    std::sync::LazyLock::new(|| StdMutex::new(OathGlobalState::new()));

struct OathGlobalState {
    keystore_state: SecretStore,
    keys: AppData,
}

impl OathGlobalState {
    fn new() -> Self {
        Self {
            keystore_state: SecretStore::Unknown,
            keys: AppData::new("oath_keys"),
        }
    }

    fn ensure_unlocked(&mut self) -> bool {
        if self.keystore_state == SecretStore::Unknown {
            match self.keys.ensure_unlocked() {
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

pub struct OathNode {
    session: Option<OathSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    key_verifier: Option<([u8; 32], [u8; 32])>,
}

impl OathNode {
    pub fn new(
        connection: Box<dyn SmartCardConnection + Send>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        scp_params: Option<&ScpKeyParams>,
    ) -> Result<Self, RpcError> {
        let result = if let Some(scp) = scp_params {
            OathSession::new_with_scp(connection, scp)
        } else {
            OathSession::new(connection)
        };
        match result {
            Ok(session) => {
                let mut node = Self {
                    session: Some(session),
                    conn,
                    key_verifier: None,
                };
                // Try auto-unlock
                node.try_auto_unlock();
                Ok(node)
            }
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }

    fn try_auto_unlock(&mut self) {
        let session = self.session.as_mut().unwrap();
        if !session.locked() {
            return;
        }
        let device_id = session.device_id().to_string();
        let mut state = OATH_STATE.lock().unwrap();
        if !state.keys.contains(&device_id) || !state.ensure_unlocked() {
            return;
        }
        match state.keys.get_secret(&device_id) {
            Ok(hex_key) => {
                if let Ok(key_bytes) = hex::decode(&hex_key)
                    && let Ok(key) = OathAccessKey::new(&key_bytes)
                {
                    match session.validate(&key) {
                        Ok(()) => {
                            drop(state); // release lock before calling self method
                            self.set_key_verifier(key.expose_secret());
                        }
                        Err(e) => {
                            log::warn!("Auto-unlock failed: {e}");
                            let _ = state.keys.remove(&device_id);
                        }
                    }
                }
            }
            Err(e) => {
                log::warn!("Failed to unwrap access key: {e}");
            }
        }
    }

    fn set_key_verifier(&mut self, key: &[u8]) {
        use hmac::{Hmac, Mac};
        use sha2::Sha256;
        let mut salt = [0u8; 32];
        getrandom::fill(&mut salt).unwrap();
        let mut mac = Hmac::<Sha256>::new_from_slice(&salt).unwrap();
        mac.update(key);
        let digest: [u8; 32] = mac.finalize().into_bytes().into();
        self.key_verifier = Some((salt, digest));
    }

    fn get_key(&self, params: &Value) -> Result<Vec<u8>, RpcError> {
        let key = params.get("key").and_then(|v| v.as_str());
        let password = params.get("password").and_then(|v| v.as_str());
        match (key, password) {
            (Some(_), Some(_)) => Err(RpcError::invalid_params(
                "Only one of 'key' and 'password' can be provided",
            )),
            (Some(k), None) => {
                hex::decode(k).map_err(|_| RpcError::invalid_params("Invalid hex key"))
            }
            (None, Some(p)) => {
                let session = self.session.as_ref().unwrap();
                Ok(session.derive_key(p).expose_secret().to_vec())
            }
            (None, None) => Err(RpcError::invalid_params(
                "One of 'key' and 'password' must be provided",
            )),
        }
    }

    fn remember_key(&mut self, key: Option<&[u8]>) -> bool {
        let session = self.session.as_ref().unwrap();
        let device_id = session.device_id().to_string();
        let mut state = OATH_STATE.lock().unwrap();
        match key {
            None => {
                if state.keys.contains(&device_id) {
                    let _ = state.keys.remove(&device_id);
                }
                true
            }
            Some(k) => {
                if state.ensure_unlocked() {
                    let _ = state.keys.put_secret(&device_id, &hex::encode(k));
                    true
                } else {
                    false
                }
            }
        }
    }
}

impl RpcNode for OathNode {
    fn get_data(&self) -> Value {
        if let Some(session) = self.session.as_ref() {
            let device_id = session.device_id().to_string();
            let state = OATH_STATE.lock().unwrap();
            json!({
                "version": version_to_json(&session.version()),
                "device_id": device_id,
                "has_key": session.has_key(),
                "locked": session.locked(),
                "remembered": state.keys.contains(&device_id),
                "keystore": state.keystore_state,
            })
        } else {
            json!({})
        }
    }

    fn list_actions(&self) -> Vec<&'static str> {
        if let Some(session) = self.session.as_ref() {
            let mut actions = vec!["derive", "validate", "set_key", "reset", "forget"];
            if session.has_key() {
                actions.push("unset_key");
            }
            actions
        } else {
            vec![]
        }
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        children.insert("accounts".to_string(), json!({}));
        children
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        self.ensure_session()?;
        let result = self.call_action_inner(action, params);
        // Handle SECURITY_CONDITION_NOT_SATISFIED as auth-required
        match result {
            Err(ref e) if e.status == "smartcard-error" && e.message.contains("6982") => {
                Err(RpcError::auth_required())
            }
            other => other,
        }
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        match name {
            "accounts" => {
                let session = self.session.as_ref().unwrap();
                if session.locked() {
                    return Err(RpcError::auth_required());
                }
                // We need to pass the session to the child, but we can't move it
                // The child will share the session via the OATH session pattern
                // For simplicity, create an AccountsNode that takes the connection
                // Actually, CredentialsNode needs the session. Since only one child at a time,
                // we can move the session out temporarily.
                // But that complicates things. Let me just pass a reference via the shared conn.
                // The CredentialsNode will open its own session.
                let conn_arc = self.conn.clone();
                // Put connection back from session
                self.ensure_session()?;
                let session = self.session.take().unwrap();
                let conn = session.into_connection();
                // Create new session for accounts node
                match OathSession::new(conn) {
                    Ok(new_session) => {
                        // Store nothing in our session - it's now owned by child
                        Ok(Box::new(CredentialsNode::new(new_session, conn_arc)))
                    }
                    Err((e, c)) => {
                        // Put connection back and recreate our session
                        *conn_arc.lock().unwrap() = Some(c);
                        Err(RpcError::new("session-error", format!("{e}")))
                    }
                }
            }
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

impl OathNode {
    /// Re-acquire the OATH session from SharedConn if it was given to a child.
    fn ensure_session(&mut self) -> Result<(), RpcError> {
        if self.session.is_some() {
            return Ok(());
        }
        let conn = self
            .conn
            .lock()
            .unwrap()
            .take()
            .ok_or_else(|| RpcError::new("session-error", "Connection not available"))?;
        match OathSession::new(conn) {
            Ok(session) => {
                self.session = Some(session);
                self.try_auto_unlock();
                Ok(())
            }
            Err((e, c)) => {
                *self.conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }

    fn call_action_inner(&mut self, action: &str, params: Value) -> Result<RpcResponse, RpcError> {
        match action {
            "derive" => {
                let password = params
                    .get("password")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing password"))?;
                let session = self.session.as_ref().unwrap();
                let key = session.derive_key(password);
                Ok(RpcResponse::new(
                    json!({ "key": hex::encode(key.expose_secret()) }),
                ))
            }
            "forget" => {
                let session = self.session.as_ref().unwrap();
                let device_id = session.device_id().to_string();
                let mut state = OATH_STATE.lock().unwrap();
                if !state.keys.contains(&device_id) {
                    return Err(RpcError::new(
                        "exception",
                        format!("KeyError('{device_id}')"),
                    ));
                }
                let _ = state.keys.remove(&device_id);
                Ok(RpcResponse::new(json!({})))
            }
            "validate" => {
                let access_key_bytes = self.get_key(&params)?;
                let remember = params
                    .get("remember")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let session = self.session.as_mut().unwrap();
                let valid = if session.locked() {
                    let key = OathAccessKey::new(&access_key_bytes)
                        .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                    match session.validate(&key) {
                        Ok(()) => {
                            self.set_key_verifier(&access_key_bytes);
                            true
                        }
                        Err(_) => false,
                    }
                } else if let Some((salt, digest)) = &self.key_verifier {
                    use hmac::{Hmac, Mac};
                    use sha2::Sha256;
                    let mut mac = Hmac::<Sha256>::new_from_slice(salt).unwrap();
                    mac.update(&access_key_bytes);
                    let verify: [u8; 32] = mac.finalize().into_bytes().into();
                    verify == *digest
                } else {
                    false
                };

                let remembered = if valid && remember {
                    self.remember_key(Some(&access_key_bytes))
                } else {
                    false
                };

                Ok(RpcResponse::new(json!({
                    "valid": valid,
                    "remembered": remembered,
                })))
            }
            "set_key" => {
                let access_key_bytes = self.get_key(&params)?;
                let remember = params
                    .get("remember")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let key = OathAccessKey::new(&access_key_bytes)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                let session = self.session.as_mut().unwrap();
                session
                    .set_key(&key)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                self.set_key_verifier(&access_key_bytes);

                let remembered = if remember {
                    self.remember_key(Some(&access_key_bytes))
                } else {
                    self.remember_key(None);
                    false
                };

                Ok(RpcResponse::with_flags(
                    json!({ "remembered": remembered }),
                    vec!["device_info"],
                ))
            }
            "unset_key" => {
                let session = self.session.as_mut().unwrap();
                session
                    .unset_key()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                self.key_verifier = None;
                self.remember_key(None);
                Ok(RpcResponse::new(json!({})))
            }
            "reset" => {
                let session = self.session.as_mut().unwrap();
                session
                    .reset()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                self.key_verifier = None;
                self.remember_key(None);
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }
}

// --- CredentialsNode ---

struct CredentialsNode {
    session: Option<OathSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    creds: BTreeMap<Vec<u8>, Credential>,
}

impl CredentialsNode {
    fn new(
        session: OathSession<Box<dyn SmartCardConnection + Send>>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    ) -> Self {
        let mut node = Self {
            session: Some(session),
            conn,
            creds: BTreeMap::new(),
        };
        node.refresh();
        node
    }

    fn refresh(&mut self) {
        if let Some(ref mut session) = self.session {
            let timestamp = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs();
            match session.calculate_all(timestamp) {
                Ok(result) => {
                    self.creds = result.into_iter().map(|(c, _)| (c.id.clone(), c)).collect();
                }
                Err(e) => {
                    log::warn!("Failed to calculate_all: {e}");
                }
            }
        }
    }
}

impl RpcNode for CredentialsNode {
    fn list_actions(&self) -> Vec<&'static str> {
        vec!["calculate_all", "put"]
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        self.creds
            .iter()
            .map(|(id, cred)| (hex::encode(id), credential_to_json(cred)))
            .collect()
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "calculate_all" => {
                let session = self.session.as_mut().unwrap();
                let timestamp = params
                    .get("timestamp")
                    .and_then(|v| v.as_u64())
                    .unwrap_or_else(|| {
                        std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs()
                    });
                let result = session
                    .calculate_all(timestamp)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                let entries: Vec<Value> = result
                    .iter()
                    .map(|(cred, code)| {
                        json!({
                            "credential": credential_to_json(cred),
                            "code": code.as_ref().map(code_to_json),
                        })
                    })
                    .collect();

                Ok(RpcResponse::new(json!({ "entries": entries })))
            }
            "put" => {
                let session = self.session.as_mut().unwrap();
                let require_touch = params
                    .get("require_touch")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let data = if let Some(uri) = params.get("uri").and_then(|v| v.as_str()) {
                    parse_otpauth_uri(uri)?
                } else {
                    let name = params
                        .get("name")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| RpcError::invalid_params("Missing name"))?;
                    let oath_type = params
                        .get("oath_type")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| RpcError::invalid_params("Missing oath_type"))?;
                    let hash = params
                        .get("hash")
                        .and_then(|v| v.as_str())
                        .unwrap_or("SHA1");
                    let secret = params
                        .get("secret")
                        .and_then(|v| v.as_str())
                        .ok_or_else(|| RpcError::invalid_params("Missing secret"))?;
                    let secret_bytes = hex::decode(secret)
                        .map_err(|_| RpcError::invalid_params("Invalid hex secret"))?;

                    let ot = match oath_type.to_uppercase().as_str() {
                        "TOTP" => OathType::Totp,
                        "HOTP" => OathType::Hotp,
                        _ => return Err(RpcError::invalid_params("Invalid oath_type")),
                    };
                    let ha = match hash.to_uppercase().as_str() {
                        "SHA1" => HashAlgorithm::Sha1,
                        "SHA256" => HashAlgorithm::Sha256,
                        "SHA512" => HashAlgorithm::Sha512,
                        _ => return Err(RpcError::invalid_params("Invalid hash algorithm")),
                    };

                    let digits = params.get("digits").and_then(|v| v.as_u64()).unwrap_or(6) as u8;
                    let period = params.get("period").and_then(|v| v.as_u64()).unwrap_or(30) as u32;
                    let counter =
                        params.get("counter").and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                    let issuer = params
                        .get("issuer")
                        .and_then(|v| v.as_str())
                        .map(String::from);

                    CredentialData {
                        name: name.to_string(),
                        oath_type: ot,
                        hash_algorithm: ha,
                        secret: secret_bytes,
                        digits,
                        period,
                        counter,
                        issuer,
                    }
                };

                let cred_id = data.get_id();
                if self.creds.contains_key(&cred_id) {
                    return Err(RpcError::invalid_params("Credential already exists"));
                }

                let credential = session
                    .put_credential(&data, require_touch)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                self.creds.insert(credential.id.clone(), credential.clone());
                Ok(RpcResponse::new(credential_to_json(&credential)))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        let key = hex::decode(name).map_err(|_| RpcError::no_such_node(name))?;
        if let Some(cred) = self.creds.get(&key).cloned() {
            // Move the session to the child
            let session = self.session.take().unwrap();
            let conn = self.conn.clone();
            Ok(Box::new(CredentialNode {
                session: Some(session),
                conn,
                credential: cred,
                touch: false,
            }))
        } else {
            Err(RpcError::no_such_node(name))
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

// --- CredentialNode ---

struct CredentialNode {
    session: Option<OathSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    credential: Credential,
    touch: bool,
}

impl RpcNode for CredentialNode {
    fn get_data(&self) -> Value {
        json!({})
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = vec!["code", "calculate", "delete"];
        // rename available on 5.3.1+
        if let Some(ref session) = self.session
            && session.version() >= yubikit::core::Version(5, 3, 1)
        {
            actions.push("rename");
        }
        actions
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "code" => {
                let session = self.session.as_mut().unwrap();
                let timestamp = params
                    .get("timestamp")
                    .and_then(|v| v.as_u64())
                    .unwrap_or_else(|| {
                        std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs()
                    });

                if self.touch || self.credential.touch_required == Some(true) {
                    signal("touch", json!({}));
                }

                let code = session
                    .calculate_code(&self.credential, timestamp)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(code_to_json(&code)))
            }
            "calculate" => {
                let session = self.session.as_mut().unwrap();
                let challenge = params
                    .get("challenge")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing challenge"))?;
                let challenge_bytes =
                    hex::decode(challenge).map_err(|_| RpcError::invalid_params("Invalid hex"))?;

                if self.touch || self.credential.touch_required == Some(true) {
                    signal("touch", json!({}));
                }

                let response = session
                    .calculate(&self.credential.id, &challenge_bytes)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(
                    json!({ "response": hex::encode(response) }),
                ))
            }
            "delete" => {
                let session = self.session.as_mut().unwrap();
                session
                    .delete_credential(&self.credential.id)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(json!({})))
            }
            "rename" => {
                let session = self.session.as_mut().unwrap();
                let name = params
                    .get("name")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing name"))?;
                let issuer = params.get("issuer").and_then(|v| v.as_str());

                let new_id = session
                    .rename_credential(&self.credential.id, name, issuer)
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                Ok(RpcResponse::new(
                    json!({ "credential_id": hex::encode(new_id) }),
                ))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.take() {
            let conn = session.into_connection();
            // Return to parent's shared conn
            // Actually this should go back to the CredentialsNode
            // but since we share the same Arc, put it back
            *self.conn.lock().unwrap() = Some(conn);
        }
    }
}

fn credential_to_json(cred: &Credential) -> Value {
    json!({
        "device_id": cred.device_id,
        "id": hex::encode(&cred.id),
        "name": cred.name,
        "issuer": cred.issuer,
        "oath_type": cred.oath_type as u8,
        "period": cred.period,
        "touch_required": cred.touch_required,
    })
}

fn code_to_json(code: &Code) -> Value {
    json!({
        "value": code.value,
        "valid_from": code.valid_from,
        "valid_to": code.valid_to,
    })
}

/// Parse an otpauth:// URI into CredentialData.
/// Format: otpauth://totp/ISSUER:NAME?secret=BASE32&algorithm=SHA1&digits=6&period=30
///     or: otpauth://hotp/NAME?secret=BASE32&counter=0
fn parse_otpauth_uri(uri: &str) -> Result<CredentialData, RpcError> {
    let uri = uri.trim();
    let rest = uri
        .strip_prefix("otpauth://")
        .ok_or_else(|| RpcError::invalid_params("URI must start with otpauth://"))?;

    // Split type/label?params
    let (type_and_label, query) = rest.split_once('?').unwrap_or((rest, ""));
    let (oath_type_str, label) = type_and_label
        .split_once('/')
        .ok_or_else(|| RpcError::invalid_params("Invalid otpauth URI format"))?;

    let oath_type = match oath_type_str.to_lowercase().as_str() {
        "totp" => OathType::Totp,
        "hotp" => OathType::Hotp,
        _ => {
            return Err(RpcError::invalid_params(format!(
                "Invalid oath type: {oath_type_str}"
            )));
        }
    };

    // URL-decode the label
    let label = percent_decode(label);

    // Parse label: "issuer:name" or just "name"
    let (issuer_from_label, name) = if let Some((issuer, name)) = label.split_once(':') {
        (Some(issuer.to_string()), name.trim().to_string())
    } else {
        (None, label)
    };

    // Parse query parameters
    let mut secret_b32 = None;
    let mut algorithm = HashAlgorithm::Sha1;
    let mut digits: u8 = 6;
    let mut period: u32 = 30;
    let mut counter: u32 = 0;
    let mut issuer_param = None;

    for param in query.split('&') {
        if param.is_empty() {
            continue;
        }
        let (key, value) = param.split_once('=').unwrap_or((param, ""));
        match key.to_lowercase().as_str() {
            "secret" => secret_b32 = Some(value.to_string()),
            "algorithm" => {
                algorithm = match value.to_uppercase().as_str() {
                    "SHA1" => HashAlgorithm::Sha1,
                    "SHA256" => HashAlgorithm::Sha256,
                    "SHA512" => HashAlgorithm::Sha512,
                    _ => {
                        return Err(RpcError::invalid_params(format!(
                            "Invalid algorithm: {value}"
                        )));
                    }
                };
            }
            "digits" => {
                digits = value
                    .parse()
                    .map_err(|_| RpcError::invalid_params("Invalid digits"))?;
            }
            "period" => {
                period = value
                    .parse()
                    .map_err(|_| RpcError::invalid_params("Invalid period"))?;
            }
            "counter" => {
                counter = value
                    .parse()
                    .map_err(|_| RpcError::invalid_params("Invalid counter"))?;
            }
            "issuer" => {
                issuer_param = Some(percent_decode(value));
            }
            _ => {} // Ignore unknown params
        }
    }

    let secret_str =
        secret_b32.ok_or_else(|| RpcError::invalid_params("Missing secret parameter"))?;
    let secret = base32::decode(
        base32::Alphabet::Rfc4648 { padding: false },
        &secret_str.to_uppercase(),
    )
    .ok_or_else(|| RpcError::invalid_params("Invalid base32 secret"))?;

    let issuer = issuer_param.or(issuer_from_label);

    Ok(CredentialData {
        name,
        oath_type,
        hash_algorithm: algorithm,
        secret,
        digits,
        period,
        counter,
        issuer,
    })
}

fn percent_decode(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let mut chars = s.bytes();
    while let Some(b) = chars.next() {
        if b == b'%' {
            let h1 = chars.next().unwrap_or(0);
            let h2 = chars.next().unwrap_or(0);
            let hex_str = [h1, h2];
            if let Ok(decoded) = u8::from_str_radix(std::str::from_utf8(&hex_str).unwrap_or(""), 16)
            {
                result.push(decoded as char);
            } else {
                result.push('%');
                result.push(h1 as char);
                result.push(h2 as char);
            }
        } else if b == b'+' {
            result.push(' ');
        } else {
            result.push(b as char);
        }
    }
    result
}
