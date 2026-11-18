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
use crate::devices::info_to_json;
use crate::error::{RpcError, RpcResponse, SecretStore};
use crate::management::ReadDeviceInfo;
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
            keys: AppData::new("oath_keys").expect("failed to open OATH app data"),
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
    scp_params: Option<ScpKeyParams>,
    key_verifier: Option<([u8; 32], [u8; 32])>,
    cached_data: Value,
    cached_actions: Vec<&'static str>,
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
                    scp_params: scp_params.cloned(),
                    key_verifier: None,
                    cached_data: json!({}),
                    cached_actions: vec![],
                };
                // Try auto-unlock
                node.try_auto_unlock();
                node.cached_data = node.get_data();
                node.cached_actions = node.list_actions();
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
        use hmac::{Hmac, KeyInit, Mac};
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
            self.cached_data.clone()
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
            self.cached_actions.clone()
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
        params: &Value,
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
                self.ensure_session()?;
                let session = self.session.as_ref().unwrap();
                if session.locked() {
                    return Err(RpcError::auth_required());
                }
                self.cached_data = self.get_data();
                self.cached_actions = self.list_actions();
                let conn_arc = self.conn.clone();
                let session = self.session.take().unwrap();
                Ok(Box::new(CredentialsNode::new(
                    session,
                    conn_arc,
                    self.scp_params.clone(),
                )))
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
    /// Re-read device info over management, as the application state affects
    /// FIPS status. Reselecting OATH drops authentication, so it is restored
    /// with the given key when there is one.
    fn refreshed_info(&mut self, key: Option<&OathAccessKey>) -> Value {
        let Some(session) = self.session.take() else {
            return Value::Null;
        };
        let (info, conn) = session.into_connection().read_device_info();
        *self.conn.lock().unwrap() = Some(conn);
        if let Err(e) = self.ensure_session() {
            log::warn!("Failed to reopen OATH after refreshing device info: {e:?}");
        } else if let (Some(key), Some(session)) = (key, self.session.as_mut())
            && session.locked()
            && let Err(e) = session.validate(key)
        {
            log::warn!("Failed to re-authenticate OATH after refreshing device info: {e}");
        }
        info.as_ref().map(info_to_json).unwrap_or(Value::Null)
    }

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
        let result = match &self.scp_params {
            Some(scp) => OathSession::new_with_scp(conn, scp),
            None => OathSession::new(conn),
        };
        match result {
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

    fn call_action_inner(&mut self, action: &str, params: &Value) -> Result<RpcResponse, RpcError> {
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
                let access_key_bytes = self.get_key(params)?;
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
                    use hmac::{Hmac, KeyInit, Mac};
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
                let access_key_bytes = self.get_key(params)?;
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

                let info = self.refreshed_info(Some(&key));
                Ok(RpcResponse::with_flags(
                    json!({ "remembered": remembered, "info": info }),
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
                let info = self.refreshed_info(None);
                Ok(RpcResponse::with_flags(
                    json!({ "info": info }),
                    vec!["device_info"],
                ))
            }
            "reset" => {
                let session = self.session.take().unwrap();
                let old_device_id = session.device_id().to_string();
                let (result, conn) = match session.reset() {
                    Ok(conn) => (Ok(()), conn),
                    Err((error, conn)) => {
                        (Err(RpcError::new("device-error", format!("{error}"))), conn)
                    }
                };
                *self.conn.lock().unwrap() = Some(conn);
                self.key_verifier = None;
                // A failed reset can still have changed the application state.
                self.cached_data = json!({});
                self.cached_actions.clear();
                if result.is_ok() {
                    let mut state = OATH_STATE.lock().unwrap();
                    if state.keys.contains(&old_device_id) {
                        state
                            .keys
                            .remove(&old_device_id)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                    }
                }
                let reopened = self.ensure_session();
                if let Err(error) = result {
                    if let Err(reopen_error) = reopened {
                        log::warn!(
                            "Failed to reopen OATH after reset failure: {}",
                            reopen_error.message
                        );
                    }
                    return Err(error);
                }
                reopened?;
                let info = self.refreshed_info(None);
                Ok(RpcResponse::with_flags(
                    json!({ "info": info }),
                    vec!["device_info"],
                ))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }
}

// --- CredentialsNode ---

struct CredentialsNode {
    session: Option<OathSession<Box<dyn SmartCardConnection + Send>>>,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    scp_params: Option<ScpKeyParams>,
    creds: BTreeMap<Vec<u8>, Credential>,
}

impl CredentialsNode {
    fn new(
        session: OathSession<Box<dyn SmartCardConnection + Send>>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        scp_params: Option<ScpKeyParams>,
    ) -> Self {
        let mut node = Self {
            session: Some(session),
            conn,
            scp_params,
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
        let result = match &self.scp_params {
            Some(scp) => OathSession::new_with_scp(conn, scp),
            None => OathSession::new(conn),
        };
        match result {
            Ok(session) => {
                self.session = Some(session);
                Ok(())
            }
            Err((e, conn)) => {
                *self.conn.lock().unwrap() = Some(conn);
                Err(RpcError::new("session-error", format!("{e}")))
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
        params: &Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        self.ensure_session()?;
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
            self.ensure_session()?;
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

    fn on_child_closed(&mut self, _name: &str) {
        match self.ensure_session() {
            Ok(()) => self.refresh(),
            Err(e) => log::warn!("Failed to refresh OATH accounts: {}", e.message),
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
        params: &Value,
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, Mutex};
    use yubikit::core::{Connection, Transport};
    use yubikit::smartcard::SmartCardError;

    struct ResetConnection {
        status: Option<u16>,
        reset: bool,
        fail_reopen: bool,
    }

    impl Connection for ResetConnection {
        type Error = SmartCardError;

        fn close(&mut self) {}
    }

    impl SmartCardConnection for ResetConnection {
        fn transport(&self) -> Transport {
            Transport::Usb
        }

        fn send_and_receive(&mut self, apdu: &[u8]) -> Result<(Vec<u8>, u16), SmartCardError> {
            match apdu[1] {
                0xa4 => {
                    if self.reset && self.fail_reopen {
                        self.fail_reopen = false;
                        return Ok((vec![], 0x6985));
                    }
                    Ok((
                        vec![0x79, 3, 5, 7, 2, 0x71, 1, u8::from(self.reset)],
                        0x9000,
                    ))
                }
                0x04 => {
                    assert_eq!(&apdu[..4], &[0, 4, 0xde, 0xad]);
                    match self.status {
                        Some(status) => {
                            self.reset = status == 0x9000;
                            Ok((vec![], status))
                        }
                        None => Err(SmartCardError::Transport(Box::new(std::io::Error::other(
                            "reset transport failure",
                        )))),
                    }
                }
                _ => panic!("Unexpected APDU: {apdu:x?}"),
            }
        }
    }

    fn reset_node(status: Option<u16>, fail_reopen: bool) -> OathNode {
        OathNode::new(
            Box::new(ResetConnection {
                status,
                reset: false,
                fail_reopen,
            }),
            Arc::new(Mutex::new(None)),
            None,
        )
        .unwrap()
    }

    #[test]
    fn cached_key_verifier_accepts_only_the_original_key() {
        let mut node = reset_node(Some(0x9000), false);
        let key = b"0123456789abcdef";
        node.set_key_verifier(key);

        for (candidate, valid) in [
            (key.as_slice(), true),
            (b"incorrect key!!!".as_slice(), false),
            (b"".as_slice(), false),
            (key.as_slice(), true),
        ] {
            let response = node
                .call_action_inner("validate", &json!({"key": hex::encode(candidate)}))
                .unwrap();
            assert_eq!(response.body, json!({"valid": valid, "remembered": false}));
        }
    }

    #[test]
    fn cached_key_verifier_matches_known_hmac_sha256_digest() {
        let mut node = reset_node(Some(0x9000), false);
        let salt = std::array::from_fn(|i| i as u8);
        let digest =
            hex::decode("75de808a0aacf75b83f1158ec2a4d3c2d60bd190f438a9a580d2bb27c32005d7")
                .unwrap()
                .try_into()
                .unwrap();
        node.key_verifier = Some((salt, digest));

        let response = node
            .call_action_inner(
                "validate",
                &json!({"key": hex::encode(b"0123456789abcdef")}),
            )
            .unwrap();
        assert_eq!(response.body, json!({"valid": true, "remembered": false}));
    }

    #[test]
    fn reset_reopens_session_on_success_status_error_and_transport_error() {
        for status in [Some(0x9000), Some(0x6982), None] {
            let mut node = reset_node(status, false);
            let old_id = node.get_data()["device_id"].clone();
            node.set_key_verifier(b"old access key");

            let result = node.call_action_inner("reset", &json!({}));
            assert_eq!(result.is_ok(), status == Some(0x9000));
            if let Err(error) = result {
                assert_eq!(error.status, "device-error");
            }
            assert!(node.session.is_some());
            assert!(node.key_verifier.is_none());
            assert_eq!(
                node.get_data()["device_id"] != old_id,
                status == Some(0x9000)
            );
            assert!(node.list_actions().contains(&"reset"));
        }
    }

    #[test]
    fn reset_preserves_connection_when_reopening_fails() {
        let mut node = reset_node(Some(0x9000), true);
        let old_id = node.get_data()["device_id"].clone();

        assert_eq!(
            node.call_action_inner("reset", &json!({}))
                .err()
                .unwrap()
                .status,
            "session-error"
        );
        assert!(node.session.is_none());
        assert!(node.conn.lock().unwrap().is_some());
        node.ensure_session().unwrap();
        assert_ne!(node.get_data()["device_id"], old_id);
    }

    #[test]
    fn returns_oath_state_while_accounts_owns_the_session() {
        let data = json!({
            "device_id": "test-id",
            "version": [5, 7, 0],
            "has_key": false,
            "locked": false,
            "remembered": false,
            "keystore": "unknown",
        });
        let node = OathNode {
            session: None,
            conn: Arc::new(Mutex::new(None)),
            scp_params: None,
            key_verifier: None,
            cached_data: data.clone(),
            cached_actions: vec!["derive", "set_key"],
        };

        assert_eq!(node.get_data(), data);
        assert_eq!(node.list_actions(), vec!["derive", "set_key"]);
    }

    #[test]
    fn accounts_report_unavailable_session_instead_of_panicking() {
        let mut node = CredentialsNode {
            session: None,
            conn: Arc::new(Mutex::new(None)),
            scp_params: None,
            creds: BTreeMap::new(),
        };

        assert_eq!(node.ensure_session().unwrap_err().status, "session-error");
    }
}
