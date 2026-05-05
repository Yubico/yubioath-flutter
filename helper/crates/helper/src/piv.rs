use std::collections::BTreeMap;
use std::str::FromStr;
use std::sync::atomic::AtomicBool;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use serde_json::{Value, json};
use sha2::Digest;

use x509_cert::Certificate;
use x509_cert::builder::{Builder, CertificateBuilder, Profile, RequestBuilder};
use x509_cert::der::{Decode, Encode, EncodePem, pem::LineEnding};
use x509_cert::name::Name;
use x509_cert::serial_number::SerialNumber;
use x509_cert::spki::SubjectPublicKeyInfoOwned;
use x509_cert::time::Validity;

use yubikit::piv::{
    HashAlgorithm, KeyType, ManagementKeyType, ObjectId, PinPolicy, PivError, PivSession,
    PivSignature, PivSigner, Slot, TouchPolicy,
};
use yubikit::smartcard::ScpKeyParams;
use yubikit::smartcard::SmartCardConnection;
use yubikit::tlv::{parse_tlv_list, tlv_encode, tlv_unpack};

use crate::connection::SharedConn;
use crate::error::{RpcError, RpcResponse};
use crate::rpc::{RpcNode, SignalFn};
use crate::util::version_to_json;

type SharedPivSession = Arc<Mutex<Option<PivSession<Box<dyn SmartCardConnection + Send>>>>>;
type KeyCertPair = (Option<Vec<u8>>, Option<Vec<u8>>);

pub struct PivNode {
    session: SharedPivSession,
    conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
    authenticated: bool,
}

impl PivNode {
    pub fn new(
        connection: Box<dyn SmartCardConnection + Send>,
        conn: SharedConn<Box<dyn SmartCardConnection + Send>>,
        scp_params: Option<&ScpKeyParams>,
    ) -> Result<Self, RpcError> {
        let result = if let Some(scp) = scp_params {
            PivSession::new_with_scp(connection, scp)
        } else {
            PivSession::new(connection)
        };
        match result {
            Ok(session) => Ok(Self {
                session: Arc::new(Mutex::new(Some(session))),
                conn,
                authenticated: false,
            }),
            Err((e, c)) => {
                *conn.lock().unwrap() = Some(c);
                Err(RpcError::new("session-error", format!("{e}")))
            }
        }
    }

    fn fetch_data(session: &mut PivSession<Box<dyn SmartCardConnection + Send>>) -> Value {
        let version = session.version();
        let pivman = get_pivman_data(session);
        let derived_key = pivman.iter().any(|(t, _)| *t == TAG_PIVMAN_SALT);
        let stored_key = has_stored_key(&pivman);

        let supports_bio = session.get_bio_metadata().is_ok();

        // Read CHUID and CCC objects
        let chuid = session.get_object(ObjectId::Chuid).ok().map(hex::encode);
        let ccc = session
            .get_object(ObjectId::Capability)
            .ok()
            .map(hex::encode);

        let mut data = json!({
            "version": version_to_json(&version),
            "derived_key": derived_key,
            "stored_key": stored_key,
            "supports_bio": supports_bio,
            "chuid": chuid,
            "ccc": ccc,
        });

        match session.get_pin_metadata() {
            Ok(pin_md) => {
                let puk_md = session.get_puk_metadata().ok();
                let mgm_md = session.get_management_key_metadata().ok();
                data["pin_attempts"] = json!(pin_md.attempts_remaining);
                data["metadata"] = json!({
                    "pin_metadata": {
                        "attempts_remaining": pin_md.attempts_remaining,
                        "total_attempts": pin_md.total_attempts,
                        "default_value": pin_md.default_value,
                    },
                    "puk_metadata": puk_md.map(|m| json!({
                        "attempts_remaining": m.attempts_remaining,
                        "total_attempts": m.total_attempts,
                        "default_value": m.default_value,
                    })),
                    "management_key_metadata": mgm_md.map(|m| json!({
                        "key_type": m.key_type as u8,
                        "touch_policy": m.touch_policy as u8,
                        "default_value": m.default_value,
                    })),
                });
            }
            Err(_) => {
                let attempts = session.get_pin_attempts().unwrap_or(0);
                data["pin_attempts"] = json!(attempts);
                data["metadata"] = json!(null);
            }
        }

        data
    }
}

impl RpcNode for PivNode {
    fn get_data(&self) -> Value {
        let mut session_guard = self.session.lock().unwrap();
        let mut data = if let Some(ref mut session) = *session_guard {
            Self::fetch_data(session)
        } else {
            json!({})
        };
        data["authenticated"] = json!(self.authenticated);
        data
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = vec![
            "verify_pin",
            "change_pin",
            "change_puk",
            "unblock_pin",
            "reset",
            "validate_rfc4514",
            "authenticate",
        ];
        if self.authenticated {
            actions.push("set_key");
        }
        actions
    }

    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();
        children.insert("slots".to_string(), json!({}));
        children
    }

    fn call_action(
        &mut self,
        action: &str,
        params: Value,
        _signal: SignalFn,
        _cancel: &AtomicBool,
    ) -> Result<RpcResponse, RpcError> {
        let result = self._call_action(action, params);
        // Wrap SW=0x6982 (Security Condition Not Satisfied) as auth-required,
        // matching Python's PivNode.__call__() behavior.
        result.map_err(|e| {
            if is_security_condition_error(&e) {
                RpcError::auth_required()
            } else {
                e
            }
        })
    }

    fn create_child(&mut self, name: &str) -> Result<Box<dyn RpcNode>, RpcError> {
        match name {
            "slots" => Ok(Box::new(SlotsNode::new(self.session.clone()))),
            _ => Err(RpcError::no_such_node(name)),
        }
    }

    fn close(&mut self) {
        if let Some(session) = self.session.lock().unwrap().take() {
            let conn = session.into_connection();
            *self.conn.lock().unwrap() = Some(conn);
        }
    }

    fn action_closes_child(&self, action: &str) -> bool {
        !matches!(action, "validate_rfc4514")
    }
}

impl PivNode {
    fn _call_action(&mut self, action: &str, params: Value) -> Result<RpcResponse, RpcError> {
        match action {
            "verify_pin" => {
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing pin"))?;
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                session.verify_pin(pin).map_err(handle_pin_error)?;

                // Try to auto-authenticate with stored management key
                let pivman = get_pivman_data(session);
                if has_stored_key(&pivman) {
                    let prot = get_pivman_protected_data(session);
                    if let Some((_, key)) = prot.iter().find(|(t, _)| *t == TAG_PIVMAN_KEY) {
                        if session.authenticate(key).is_ok() {
                            self.authenticated = true;
                        }
                        // Re-verify PIN so it was the last operation
                        let _ = session.verify_pin(pin);
                    }
                }

                Ok(RpcResponse::new(json!({
                    "status": true,
                    "authenticated": self.authenticated,
                })))
            }
            "authenticate" => {
                let key_hex = params
                    .get("key")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing key"))?;
                let key = hex::decode(key_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid hex key"))?;
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();

                match session.authenticate(&key) {
                    Ok(()) => {
                        self.authenticated = true;
                        Ok(RpcResponse::new(json!({ "status": true })))
                    }
                    Err(_) => Ok(RpcResponse::new(json!({ "status": false }))),
                }
            }
            "set_key" => {
                let key_hex = params
                    .get("key")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing key"))?;
                let key = hex::decode(key_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid hex key"))?;
                let key_type_val = params
                    .get("key_type")
                    .and_then(|v| v.as_u64())
                    .unwrap_or(ManagementKeyType::Tdes as u64);
                let key_type = ManagementKeyType::from_u8(key_type_val as u8)
                    .unwrap_or(ManagementKeyType::Tdes);
                let store_key = params
                    .get("store_key")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                pivman_set_mgm_key(session, key_type, &key, store_key)
                    .map_err(|e| RpcError::new("device-error", e.to_string()))?;
                self.authenticated = true;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "change_pin" => {
                let pin = params
                    .get("pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing pin"))?;
                let new_pin = params
                    .get("new_pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing new_pin"))?;
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                session.change_pin(pin, new_pin).map_err(handle_pin_error)?;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "change_puk" => {
                let puk = params
                    .get("puk")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing puk"))?;
                let new_puk = params
                    .get("new_puk")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing new_puk"))?;
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                session.change_puk(puk, new_puk).map_err(handle_pin_error)?;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "unblock_pin" => {
                let puk = params
                    .get("puk")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing puk"))?;
                let new_pin = params
                    .get("new_pin")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing new_pin"))?;
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                session
                    .unblock_pin(puk, new_pin)
                    .map_err(handle_pin_error)?;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "reset" => {
                let mut session_guard = self.session.lock().unwrap();
                let session = session_guard.as_mut().unwrap();
                session
                    .reset()
                    .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                self.authenticated = false;
                Ok(RpcResponse::with_flags(json!({}), vec!["device_info"]))
            }
            "validate_rfc4514" => {
                let data = params
                    .get("data")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing data"))?;
                let status = Name::from_str(data).is_ok();
                Ok(RpcResponse::new(json!({ "status": status })))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }
}

/// Check if an RpcError wraps a SW=0x6982 (Security Condition Not Satisfied).
fn is_security_condition_error(e: &RpcError) -> bool {
    e.status == "device-error" && e.message.contains("SW=0x6982")
}

fn handle_pin_error(e: PivError) -> RpcError {
    match &e {
        PivError::InvalidPin(attempts_remaining) => RpcError::with_body(
            "invalid-pin",
            "Wrong PIN",
            json!({ "attempts_remaining": attempts_remaining }),
        ),
        _ => RpcError::new("device-error", format!("{e}")),
    }
}

// --- Pivman data helpers ---

const PIVMAN_OBJ_ID: u32 = 0x5FFF00;
const PIVMAN_PROTECTED_OBJ_ID: u32 = ObjectId::Printed as u32;

const TAG_PIVMAN_DATA: u32 = 0x80;
const TAG_PIVMAN_FLAGS: u32 = 0x81;
const TAG_PIVMAN_SALT: u32 = 0x82;
const TAG_PIVMAN_PROTECTED: u32 = 0x88;
const TAG_PIVMAN_KEY: u32 = 0x89;

const PIVMAN_FLAG_KEY_PROTECTED: u8 = 0x02;

fn get_pivman_data(session: &mut PivSession<impl SmartCardConnection>) -> Vec<(u32, Vec<u8>)> {
    session
        .get_object_raw(PIVMAN_OBJ_ID)
        .ok()
        .and_then(|raw| {
            let inner = tlv_unpack(TAG_PIVMAN_DATA, &raw).ok()?;
            parse_tlv_list(&inner).ok()
        })
        .unwrap_or_default()
}

fn has_stored_key(pivman: &[(u32, Vec<u8>)]) -> bool {
    pivman
        .iter()
        .find(|(t, _)| *t == TAG_PIVMAN_FLAGS)
        .is_some_and(|(_, v)| !v.is_empty() && (v[0] & PIVMAN_FLAG_KEY_PROTECTED) != 0)
}

fn put_pivman_data(
    session: &mut PivSession<impl SmartCardConnection>,
    entries: &[(u32, Vec<u8>)],
) -> Result<(), String> {
    let mut inner = Vec::new();
    for (tag, val) in entries {
        inner.extend_from_slice(&tlv_encode(*tag, val));
    }
    let outer = if inner.is_empty() {
        vec![]
    } else {
        tlv_encode(TAG_PIVMAN_DATA, &inner)
    };
    session
        .put_object_raw(PIVMAN_OBJ_ID, Some(&outer))
        .map_err(|e| format!("Failed to write pivman data: {e}"))
}

fn get_pivman_protected_data(
    session: &mut PivSession<impl SmartCardConnection>,
) -> Vec<(u32, Vec<u8>)> {
    session
        .get_object_raw(PIVMAN_PROTECTED_OBJ_ID)
        .ok()
        .and_then(|raw| {
            let inner = tlv_unpack(TAG_PIVMAN_PROTECTED, &raw).ok()?;
            parse_tlv_list(&inner).ok()
        })
        .unwrap_or_default()
}

fn put_pivman_protected_data(
    session: &mut PivSession<impl SmartCardConnection>,
    entries: &[(u32, Vec<u8>)],
) -> Result<(), String> {
    let mut inner = Vec::new();
    for (tag, val) in entries {
        inner.extend_from_slice(&tlv_encode(*tag, val));
    }
    let outer = if inner.is_empty() {
        vec![]
    } else {
        tlv_encode(TAG_PIVMAN_PROTECTED, &inner)
    };
    session
        .put_object_raw(PIVMAN_PROTECTED_OBJ_ID, Some(&outer))
        .map_err(|e| format!("Failed to write pivman protected data: {e}"))
}

fn set_tlv_entry(entries: &mut Vec<(u32, Vec<u8>)>, tag: u32, value: Option<Vec<u8>>) {
    entries.retain(|(t, _)| *t != tag);
    if let Some(v) = value {
        entries.push((tag, v));
    }
}

/// Set the management key and keep pivman data in sync.
fn pivman_set_mgm_key(
    session: &mut PivSession<impl SmartCardConnection>,
    key_type: ManagementKeyType,
    new_key: &[u8],
    store_on_device: bool,
) -> Result<(), String> {
    let mut pivman = get_pivman_data(session);
    let was_stored = has_stored_key(&pivman);

    // If we need to read/clear protected data, get it now (while PIN is still verified)
    let mut prot = if store_on_device || was_stored {
        Some(get_pivman_protected_data(session))
    } else {
        None
    };

    // Set the actual management key on the device
    session
        .set_management_key(key_type, new_key, false)
        .map_err(|e| format!("Failed to set management key: {e}"))?;

    // Update the stored-key flag
    let current_flags = pivman
        .iter()
        .find(|(t, _)| *t == TAG_PIVMAN_FLAGS)
        .map(|(_, v)| if v.is_empty() { 0u8 } else { v[0] })
        .unwrap_or(0);

    let new_flags = if store_on_device {
        current_flags | PIVMAN_FLAG_KEY_PROTECTED
    } else {
        current_flags & !PIVMAN_FLAG_KEY_PROTECTED
    };

    if new_flags != 0 {
        set_tlv_entry(&mut pivman, TAG_PIVMAN_FLAGS, Some(vec![new_flags]));
    } else {
        set_tlv_entry(&mut pivman, TAG_PIVMAN_FLAGS, None);
    }

    put_pivman_data(session, &pivman)?;

    // Update protected data
    if let Some(ref mut prot_entries) = prot {
        if store_on_device {
            set_tlv_entry(prot_entries, TAG_PIVMAN_KEY, Some(new_key.to_vec()));
        } else {
            set_tlv_entry(prot_entries, TAG_PIVMAN_KEY, None);
        }
        put_pivman_protected_data(session, prot_entries)?;
    }

    Ok(())
}

/// Generate and write a new CHUID to the device.
fn generate_chuid(session: &mut PivSession<impl SmartCardConnection>) -> Result<(), RpcError> {
    let mut chuid = Vec::new();
    chuid.extend_from_slice(&[0x30, 0x19]);
    chuid.extend_from_slice(&[0x9E; 25]);
    chuid.push(0x34);
    chuid.push(0x10);
    let mut guid = [0u8; 16];
    getrandom::fill(&mut guid).map_err(|e| RpcError::new("rng-error", format!("{e}")))?;
    guid[6] = (guid[6] & 0x0f) | 0x40;
    guid[8] = (guid[8] & 0x3f) | 0x80;
    chuid.extend_from_slice(&guid);
    chuid.push(0x35);
    chuid.push(0x08);
    chuid.extend_from_slice(b"20301231");
    chuid.push(0x3E);
    chuid.push(0x00);
    chuid.push(0xFE);
    chuid.push(0x00);

    session
        .put_object(ObjectId::Chuid, Some(&chuid))
        .map_err(|e| RpcError::new("device-error", format!("Failed to update CHUID: {e}")))?;
    Ok(())
}

// --- Certificate/key parsing helpers ---

fn parse_cert_info(cert_der: &[u8]) -> Option<Value> {
    let fingerprint = hex::encode(sha2::Sha256::digest(cert_der));
    let cert = Certificate::from_der(cert_der).ok()?;
    let tbs = &cert.tbs_certificate;

    let subject = tbs.subject.to_string();
    let issuer = tbs.issuer.to_string();
    let serial = hex::encode(tbs.serial_number.as_bytes());
    let not_before = tbs.validity.not_before.to_string();
    let not_after = tbs.validity.not_after.to_string();

    let key_type =
        KeyType::from_public_key_der(&tbs.subject_public_key_info.to_der().unwrap_or_default())
            .map(|kt| json!(kt as u8))
            .unwrap_or(json!(null));

    Some(json!({
        "key_type": key_type,
        "subject": subject,
        "issuer": issuer,
        "serial": serial,
        "not_valid_before": not_before,
        "not_valid_after": not_after,
        "fingerprint": fingerprint,
    }))
}

/// Decode PEM data (first block) to DER bytes.
fn pem_decode(text: &str) -> Result<Vec<u8>, RpcError> {
    let (_, der) = der::Document::from_pem(text)
        .map_err(|e| RpcError::new("parse-error", format!("Failed to decode PEM: {e}")))?;
    Ok(der.to_vec())
}

/// Check if data looks like a PKCS#12 file.
fn is_pkcs12(data: &[u8]) -> bool {
    if data.len() < 10 || data[0] != 0x30 {
        return false;
    }
    let len_byte = data[1];
    let offset = if len_byte & 0x80 == 0 {
        2
    } else {
        2 + (len_byte & 0x7f) as usize
    };
    offset + 3 <= data.len()
        && data[offset] == 0x02
        && data[offset + 1] == 0x01
        && data[offset + 2] == 0x03
}

/// Result of parsing a file for import.
struct ParsedFile {
    private_key: Option<Vec<u8>>,
    certificate: Option<Vec<u8>>,
    /// The file requires a password that was not provided (or was wrong).
    password_required: bool,
}

/// Parse file data into (optional private key DER, optional cert DER).
/// Handles PEM, DER, encrypted PEM, and PKCS#12.
fn parse_file(data: &[u8], password: Option<&str>) -> ParsedFile {
    let mut private_key = None;
    let mut certificate = None;

    // Try to parse as text (PEM)
    if let Ok(text) = std::str::from_utf8(data)
        && text.contains("-----BEGIN")
    {
        // Try certificate PEM
        if text.contains("CERTIFICATE")
            && let Ok(der) = pem_decode(text)
            && Certificate::from_der(&der).is_ok()
        {
            certificate = Some(der);
        }

        // Try private key PEM
        let mut password_required = false;
        if text.contains("ENCRYPTED") {
            if let Some(pw) = password {
                if let Ok(der) = decrypt_pem_private_key(text, pw) {
                    private_key = Some(der);
                } else {
                    password_required = true;
                }
            } else {
                password_required = true;
            }
        } else if text.contains("PRIVATE KEY")
            && let Ok(der) = pem_decode(text)
        {
            private_key = Some(der);
        }

        return ParsedFile {
            private_key,
            certificate,
            password_required,
        };
    }

    // Try PKCS#12
    if is_pkcs12(data) {
        let pw = password.unwrap_or("");
        if let Ok((key, cert)) = extract_from_pkcs12(data, pw) {
            private_key = key;
            certificate = cert;
        }
        let password_required = private_key.is_none() && certificate.is_none();
        return ParsedFile {
            private_key,
            certificate,
            password_required,
        };
    }

    // Try as DER certificate
    if Certificate::from_der(data).is_ok() {
        certificate = Some(data.to_vec());
    }

    // Try as DER private key (PKCS#8)
    if KeyType::from_private_key_der(data).is_ok() {
        private_key = Some(data.to_vec());
    }

    ParsedFile {
        private_key,
        certificate,
        password_required: false,
    }
}

fn decrypt_pem_private_key(pem_text: &str, password: &str) -> Result<Vec<u8>, RpcError> {
    use pkcs8::EncryptedPrivateKeyInfo;

    let der = pem_decode(pem_text)?;
    let enc_key = EncryptedPrivateKeyInfo::try_from(der.as_slice())
        .map_err(|e| RpcError::new("parse-error", format!("Failed to parse encrypted key: {e}")))?;
    let dec_key = enc_key
        .decrypt(password)
        .map_err(|_| RpcError::new("wrong-password", "Wrong password for encrypted key"))?;
    Ok(dec_key.as_bytes().to_vec())
}

fn extract_from_pkcs12(data: &[u8], password: &str) -> Result<KeyCertPair, RpcError> {
    use p12_keystore::{KeyStore, KeyStoreEntry};

    let ks = KeyStore::from_pkcs12(data, password)
        .map_err(|e| RpcError::new("parse-error", format!("Failed to parse PKCS#12: {e}")))?;

    let mut private_key = None;
    let mut certificate = None;

    // Try to get key + cert from a key chain first
    if let Some((_, chain)) = ks.private_key_chain() {
        private_key = Some(chain.key().to_vec());
        if let Some(cert) = chain.chain().first() {
            certificate = Some(cert.as_der().to_vec());
        }
    }

    // If no cert from chain, look for standalone certs
    if certificate.is_none() {
        for (_, entry) in ks.entries() {
            if let KeyStoreEntry::Certificate(cert) = entry {
                certificate = Some(cert.as_der().to_vec());
                break;
            }
        }
    }

    Ok((private_key, certificate))
}

fn random_serial_number() -> Result<SerialNumber, RpcError> {
    let mut buf = [0u8; 16];
    getrandom::fill(&mut buf).map_err(|e| RpcError::new("rng-error", format!("{e}")))?;
    buf[0] &= 0x7F;
    if buf[0] == 0 {
        buf[0] = 0x01;
    }
    SerialNumber::new(&buf).map_err(|e| RpcError::new("serial-error", format!("{e}")))
}

// --- SlotsNode ---

struct SlotsNode {
    session: SharedPivSession,
}

impl SlotsNode {
    fn new(session: SharedPivSession) -> Self {
        Self { session }
    }
}

impl RpcNode for SlotsNode {
    fn list_children(&mut self) -> BTreeMap<String, Value> {
        let mut children = BTreeMap::new();

        if let Some(ref mut session) = *self.session.lock().unwrap() {
            for slot in all_slots() {
                let slot_hex = format!("{:02x}", slot as u8);

                // Try to get metadata (5.3.0+)
                let metadata = session.get_slot_metadata(slot).ok();

                // Try to get certificate
                let cert_der = session.get_certificate(slot).ok();

                let metadata_json = metadata.as_ref().map(metadata_to_json);
                let cert_info = cert_der.as_ref().and_then(|der| parse_cert_info(der));
                let public_key_match = match (&cert_der, &metadata) {
                    (Some(cert), Some(meta)) => Some(public_key_match(cert, meta)),
                    _ => None,
                };

                let info = json!({
                    "slot": slot as u8,
                    "name": slot_name(slot),
                    "metadata": metadata_json,
                    "cert_info": cert_info,
                    "public_key_match": public_key_match,
                });

                children.insert(slot_hex, info);
            }
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
        let slot_num = u8::from_str_radix(name, 16).map_err(|_| RpcError::no_such_node(name))?;
        let slot = Slot::from_u8(slot_num).ok_or_else(|| RpcError::no_such_node(name))?;

        if self.session.lock().unwrap().is_none() {
            return Err(RpcError::new("session-error", "No active PIV session"));
        }

        Ok(Box::new(SlotNode::new(self.session.clone(), slot)))
    }
}

// --- SlotNode ---

struct SlotNode {
    session: SharedPivSession,
    slot: Slot,
    cached_metadata: Option<yubikit::piv::SlotMetadata>,
    cached_cert_der: Option<Vec<u8>>,
}

impl SlotNode {
    fn new(session: SharedPivSession, slot: Slot) -> Self {
        let (metadata, cert_der) = {
            let mut guard = session.lock().unwrap();
            let s = guard.as_mut().unwrap();
            (s.get_slot_metadata(slot).ok(), s.get_certificate(slot).ok())
        };
        Self {
            session,
            slot,
            cached_metadata: metadata,
            cached_cert_der: cert_der,
        }
    }

    fn refresh_cache(&mut self) {
        if let Some(ref mut session) = *self.session.lock().unwrap() {
            self.cached_metadata = session.get_slot_metadata(self.slot).ok();
            self.cached_cert_der = session.get_certificate(self.slot).ok();
        }
    }
}

impl RpcNode for SlotNode {
    fn get_data(&self) -> Value {
        let metadata_json = self.cached_metadata.as_ref().map(metadata_to_json);
        let cert_pem = self.cached_cert_der.as_ref().and_then(|der| {
            Certificate::from_der(der)
                .ok()
                .and_then(|cert| cert.to_pem(LineEnding::LF).ok())
        });
        json!({
            "id": format!("{:02x}", self.slot as u8),
            "name": slot_name(self.slot),
            "metadata": metadata_json,
            "certificate": cert_pem,
        })
    }

    fn list_actions(&self) -> Vec<&'static str> {
        let mut actions = vec!["examine_file", "import_file", "generate"];
        if self.cached_cert_der.is_some() || self.cached_metadata.is_some() {
            actions.push("delete");
        }
        if self.cached_metadata.is_some() {
            actions.push("move_key");
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
        self._call_action(action, params, signal).map_err(|e| {
            if is_security_condition_error(&e) {
                RpcError::auth_required()
            } else {
                e
            }
        })
    }
}

impl SlotNode {
    fn _call_action(
        &mut self,
        action: &str,
        params: Value,
        signal: SignalFn,
    ) -> Result<RpcResponse, RpcError> {
        match action {
            "delete" => {
                {
                    let mut session_guard = self.session.lock().unwrap();
                    let session = session_guard.as_mut().unwrap();
                    let delete_cert = params
                        .get("delete_cert")
                        .and_then(|v| v.as_bool())
                        .unwrap_or(false);
                    let delete_key = params
                        .get("delete_key")
                        .and_then(|v| v.as_bool())
                        .unwrap_or(false);

                    if !delete_cert && !delete_key {
                        return Err(RpcError::invalid_params("Missing delete option"));
                    }

                    if delete_cert {
                        session
                            .delete_certificate(self.slot)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                        generate_chuid(session)?;
                    }
                    if delete_key {
                        session
                            .delete_key(self.slot)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                    }
                }
                self.refresh_cache();

                Ok(RpcResponse::new(json!({})))
            }
            "move_key" => {
                let dest_str = params
                    .get("destination")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing destination"))?;
                let dest_num = u8::from_str_radix(dest_str, 16)
                    .map_err(|_| RpcError::invalid_params("Invalid destination slot"))?;
                let dest = Slot::from_u8(dest_num)
                    .ok_or_else(|| RpcError::invalid_params("Invalid destination slot"))?;
                let overwrite_key = params
                    .get("overwrite_key")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);
                let include_certificate = params
                    .get("include_certificate")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                {
                    let mut session_guard = self.session.lock().unwrap();
                    let session = session_guard.as_mut().unwrap();

                    // Read source cert object if we need to move it
                    let source_object = if include_certificate {
                        session.get_object(ObjectId::from_slot(self.slot)).ok()
                    } else {
                        None
                    };

                    if overwrite_key {
                        session
                            .delete_key(dest)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                    }
                    session
                        .move_key(self.slot, dest)
                        .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                    if include_certificate {
                        if let Some(obj) = source_object {
                            session
                                .put_object(ObjectId::from_slot(dest), Some(&obj))
                                .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                        }
                        session
                            .delete_certificate(self.slot)
                            .map_err(|e| RpcError::new("device-error", format!("{e}")))?;
                        generate_chuid(session)?;
                    }
                }
                self.refresh_cache();

                Ok(RpcResponse::new(json!({})))
            }
            "examine_file" => {
                let data_hex = params
                    .get("data")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing data"))?;
                let data = hex::decode(data_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid hex data"))?;
                let password = params.get("password").and_then(|v| v.as_str());

                let parsed = parse_file(&data, password);

                if parsed.password_required
                    && parsed.private_key.is_none()
                    && parsed.certificate.is_none()
                {
                    return Ok(RpcResponse::new(json!({"status": false})));
                }

                // Determine key type from private key
                let key_type = parsed.private_key.as_ref().and_then(|der| {
                    KeyType::from_private_key_der(der)
                        .ok()
                        .map(|kt| json!(kt as u8))
                });

                // Get cert info
                let cert_info = parsed
                    .certificate
                    .as_ref()
                    .and_then(|der| parse_cert_info(der));

                Ok(RpcResponse::new(json!({
                    "status": true,
                    "password": password.is_some(),
                    "key_type": key_type,
                    "cert_info": cert_info,
                })))
            }
            "import_file" => {
                let data_hex = params
                    .get("data")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| RpcError::invalid_params("Missing data"))?;
                let data = hex::decode(data_hex)
                    .map_err(|_| RpcError::invalid_params("Invalid hex data"))?;
                let password = params.get("password").and_then(|v| v.as_str());

                let parsed = parse_file(&data, password);

                if parsed.private_key.is_none() && parsed.certificate.is_none() {
                    if parsed.password_required {
                        return Err(RpcError::new("password-required", "Password is required"));
                    }
                    return Err(RpcError::invalid_params("Failed to parse"));
                }

                let private_key_der = parsed.private_key;
                let certificate_der = parsed.certificate;

                let (public_key_pem, cert_pem, import_metadata) = {
                    let mut session_guard = self.session.lock().unwrap();
                    let session = session_guard.as_mut().unwrap();

                    let mut public_key_pem: Option<String> = None;
                    if let Some(ref key_der) = private_key_der {
                        let key_type = KeyType::from_private_key_der(key_der).map_err(|_| {
                            RpcError::new("parse-error", "Could not determine key type")
                        })?;
                        let inner_key =
                            KeyType::extract_private_key_from_pkcs8(key_der).map_err(|e| {
                                RpcError::new("parse-error", format!("Failed to extract key: {e}"))
                            })?;

                        let pin_policy_val = params
                            .get("pin_policy")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(PinPolicy::Default as u64);
                        let pin_policy = PinPolicy::from_u8(pin_policy_val as u8)
                            .ok_or_else(|| RpcError::invalid_params("Invalid pin_policy"))?;
                        let touch_policy_val = params
                            .get("touch_policy")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(TouchPolicy::Default as u64);
                        let touch_policy = TouchPolicy::from_u8(touch_policy_val as u8)
                            .ok_or_else(|| RpcError::invalid_params("Invalid touch_policy"))?;

                        session
                            .put_key(self.slot, key_type, &inner_key, pin_policy, touch_policy)
                            .map_err(|e| {
                                RpcError::new("device-error", format!("Failed to import key: {e}"))
                            })?;

                        // Try to get the public key in SPKI PEM form
                        if let Ok(metadata) = session.get_slot_metadata(self.slot)
                            && let Ok(spki) =
                                SubjectPublicKeyInfoOwned::from_der(&metadata.public_key_der)
                            && let Ok(pem) = spki.to_pem(LineEnding::LF)
                        {
                            public_key_pem = Some(pem);
                        }
                    }

                    let mut cert_pem: Option<String> = None;
                    if let Some(ref cert_der) = certificate_der {
                        session
                            .put_certificate(self.slot, cert_der, false)
                            .map_err(|e| {
                                RpcError::new(
                                    "device-error",
                                    format!("Failed to import certificate: {e}"),
                                )
                            })?;
                        generate_chuid(session)?;

                        if let Ok(cert) = Certificate::from_der(cert_der)
                            && let Ok(pem) = cert.to_pem(LineEnding::LF)
                        {
                            cert_pem = Some(pem);
                        }
                    }

                    // Get metadata for response (matching Python)
                    let import_metadata = if private_key_der.is_some() {
                        session
                            .get_slot_metadata(self.slot)
                            .ok()
                            .map(|m| metadata_to_json(&m))
                    } else {
                        None
                    };

                    (public_key_pem, cert_pem, import_metadata)
                };
                self.refresh_cache();

                Ok(RpcResponse::with_flags(
                    json!({
                        "metadata": import_metadata,
                        "public_key": public_key_pem,
                        "certificate": cert_pem,
                    }),
                    vec!["device_info"],
                ))
            }
            "generate" => {
                let key_type_val = params
                    .get("key_type")
                    .and_then(|v| v.as_u64())
                    .ok_or_else(|| RpcError::invalid_params("Missing key_type"))?;
                let key_type = KeyType::from_u8(key_type_val as u8)
                    .ok_or_else(|| RpcError::invalid_params("Invalid key_type"))?;
                let pin_policy_val = params
                    .get("pin_policy")
                    .and_then(|v| v.as_u64())
                    .unwrap_or(PinPolicy::Default as u64);
                let pin_policy = PinPolicy::from_u8(pin_policy_val as u8)
                    .ok_or_else(|| RpcError::invalid_params("Invalid pin_policy"))?;
                let touch_policy_val = params
                    .get("touch_policy")
                    .and_then(|v| v.as_u64())
                    .unwrap_or(TouchPolicy::Default as u64);
                let touch_policy = TouchPolicy::from_u8(touch_policy_val as u8)
                    .ok_or_else(|| RpcError::invalid_params("Invalid touch_policy"))?;

                let (public_key_pem, result) = {
                    let mut session_guard = self.session.lock().unwrap();
                    let session = session_guard.as_mut().unwrap();

                    // Generate the key (returns SPKI DER directly)
                    let spki_der = session
                        .generate_key(self.slot, key_type, pin_policy, touch_policy)
                        .map_err(|e| RpcError::new("device-error", format!("{e}")))?;

                    // Encode as PEM for the response
                    let spki = SubjectPublicKeyInfoOwned::from_der(&spki_der).map_err(|e| {
                        RpcError::new("device-error", format!("Failed to parse SPKI: {e}"))
                    })?;
                    let public_key_pem = spki.to_pem(LineEnding::LF).map_err(|e| {
                        RpcError::new("device-error", format!("Failed to encode PEM: {e}"))
                    })?;

                    let generate_type = params
                        .get("generate_type")
                        .and_then(|v| v.as_str())
                        .unwrap_or("certificate");

                    // Verify PIN if needed (for signing operations)
                    if generate_type != "publicKey"
                        && pin_policy != PinPolicy::Never
                        && let Some(pin) = params.get("pin").and_then(|v| v.as_str())
                    {
                        session.verify_pin(pin).map_err(handle_pin_error)?;
                    }

                    if touch_policy == TouchPolicy::Always || touch_policy == TouchPolicy::Cached {
                        signal("touch", json!(null));
                    }

                    let result = match generate_type {
                        "publicKey" => public_key_pem.clone(),
                        "csr" => {
                            let subject = params
                                .get("subject")
                                .and_then(|v| v.as_str())
                                .ok_or_else(|| RpcError::invalid_params("Missing subject"))?;
                            let subject_name = Name::from_str(subject).map_err(|e| {
                                RpcError::invalid_params(format!("Invalid subject DN: {e}"))
                            })?;

                            let hash_alg = hash_algorithm_for_key_type(key_type);
                            let signer =
                                PivSigner::new(session, self.slot, key_type, hash_alg, &spki_der);
                            let builder =
                                RequestBuilder::new(subject_name, &signer).map_err(|e| {
                                    RpcError::new(
                                        "device-error",
                                        format!("Failed to create CSR builder: {e}"),
                                    )
                                })?;

                            let csr = builder.build::<PivSignature>().map_err(|e| {
                                RpcError::new("device-error", format!("Failed to build CSR: {e}"))
                            })?;

                            csr.to_pem(LineEnding::LF).map_err(|e| {
                                RpcError::new(
                                    "device-error",
                                    format!("Failed to encode CSR PEM: {e}"),
                                )
                            })?
                        }
                        "certificate" => {
                            let subject = params
                                .get("subject")
                                .and_then(|v| v.as_str())
                                .ok_or_else(|| RpcError::invalid_params("Missing subject"))?;
                            let subject_name = Name::from_str(subject).map_err(|e| {
                                RpcError::invalid_params(format!("Invalid subject DN: {e}"))
                            })?;

                            // Parse validity dates (YYYY-MM-DD format)
                            let now = chrono::Utc::now();
                            let default_from = now.format("%Y-%m-%d").to_string();
                            let default_to = (now + chrono::Duration::days(365))
                                .format("%Y-%m-%d")
                                .to_string();
                            let valid_from_str = params
                                .get("valid_from")
                                .and_then(|v| v.as_str())
                                .unwrap_or(&default_from);
                            let valid_to_str = params
                                .get("valid_to")
                                .and_then(|v| v.as_str())
                                .unwrap_or(&default_to);

                            let not_before =
                                chrono::NaiveDate::parse_from_str(valid_from_str, "%Y-%m-%d")
                                    .map_err(|e| {
                                        RpcError::invalid_params(format!(
                                            "Invalid valid_from date: {e}"
                                        ))
                                    })?;
                            let not_after =
                                chrono::NaiveDate::parse_from_str(valid_to_str, "%Y-%m-%d")
                                    .map_err(|e| {
                                        RpcError::invalid_params(format!(
                                            "Invalid valid_to date: {e}"
                                        ))
                                    })?;

                            let duration_secs =
                                (not_after - not_before).num_seconds().max(0) as u64;

                            let serial = random_serial_number()?;
                            let validity = Validity::from_now(Duration::from_secs(duration_secs))
                                .map_err(|e| {
                                RpcError::new("device-error", format!("Invalid validity: {e}"))
                            })?;

                            let hash_alg = hash_algorithm_for_key_type(key_type);

                            let cert_der = {
                                let signer = PivSigner::new(
                                    session, self.slot, key_type, hash_alg, &spki_der,
                                );
                                let builder = CertificateBuilder::new(
                                    Profile::Root,
                                    serial,
                                    validity,
                                    subject_name,
                                    spki.clone(),
                                    &signer,
                                )
                                .map_err(|e| {
                                    RpcError::new(
                                        "device-error",
                                        format!("Failed to create cert builder: {e}"),
                                    )
                                })?;

                                let cert = builder.build::<PivSignature>().map_err(|e| {
                                    RpcError::new(
                                        "device-error",
                                        format!("Failed to build certificate: {e}"),
                                    )
                                })?;

                                cert.to_der().map_err(|e| {
                                    RpcError::new(
                                        "device-error",
                                        format!("Failed to encode certificate: {e}"),
                                    )
                                })?
                            };

                            // Store the certificate on the device
                            session
                                .put_certificate(self.slot, &cert_der, false)
                                .map_err(|e| {
                                    RpcError::new(
                                        "device-error",
                                        format!("Failed to store certificate: {e}"),
                                    )
                                })?;
                            generate_chuid(session)?;

                            let cert = Certificate::from_der(&cert_der).map_err(|e| {
                                RpcError::new(
                                    "device-error",
                                    format!("Failed to parse certificate: {e}"),
                                )
                            })?;
                            cert.to_pem(LineEnding::LF).map_err(|e| {
                                RpcError::new("device-error", format!("Failed to encode PEM: {e}"))
                            })?
                        }
                        other => {
                            return Err(RpcError::invalid_params(format!(
                                "Invalid generate_type: {other}"
                            )));
                        }
                    };

                    (public_key_pem, result)
                };

                self.refresh_cache();
                Ok(RpcResponse::with_flags(
                    json!({
                        "public_key": public_key_pem,
                        "result": result,
                    }),
                    vec!["device_info"],
                ))
            }
            _ => Err(RpcError::no_such_action(action)),
        }
    }
}

/// Choose an appropriate hash algorithm for the given key type.
fn hash_algorithm_for_key_type(key_type: KeyType) -> HashAlgorithm {
    match key_type {
        KeyType::EccP384 => HashAlgorithm::Sha384,
        _ => HashAlgorithm::Sha256,
    }
}

/// All PIV slots except Attestation (matching Python's `set(SLOT) - {SLOT.ATTESTATION}`).
fn all_slots() -> Vec<Slot> {
    vec![
        Slot::Authentication,
        Slot::Signature,
        Slot::KeyManagement,
        Slot::CardAuth,
        Slot::Retired1,
        Slot::Retired2,
        Slot::Retired3,
        Slot::Retired4,
        Slot::Retired5,
        Slot::Retired6,
        Slot::Retired7,
        Slot::Retired8,
        Slot::Retired9,
        Slot::Retired10,
        Slot::Retired11,
        Slot::Retired12,
        Slot::Retired13,
        Slot::Retired14,
        Slot::Retired15,
        Slot::Retired16,
        Slot::Retired17,
        Slot::Retired18,
        Slot::Retired19,
        Slot::Retired20,
    ]
}

/// Get the Python-compatible slot name (UPPERCASE, matching Python IntEnum `.name`).
fn slot_name(slot: Slot) -> &'static str {
    match slot {
        Slot::Authentication => "AUTHENTICATION",
        Slot::Signature => "SIGNATURE",
        Slot::KeyManagement => "KEY_MANAGEMENT",
        Slot::CardAuth => "CARD_AUTH",
        Slot::Retired1 => "RETIRED1",
        Slot::Retired2 => "RETIRED2",
        Slot::Retired3 => "RETIRED3",
        Slot::Retired4 => "RETIRED4",
        Slot::Retired5 => "RETIRED5",
        Slot::Retired6 => "RETIRED6",
        Slot::Retired7 => "RETIRED7",
        Slot::Retired8 => "RETIRED8",
        Slot::Retired9 => "RETIRED9",
        Slot::Retired10 => "RETIRED10",
        Slot::Retired11 => "RETIRED11",
        Slot::Retired12 => "RETIRED12",
        Slot::Retired13 => "RETIRED13",
        Slot::Retired14 => "RETIRED14",
        Slot::Retired15 => "RETIRED15",
        Slot::Retired16 => "RETIRED16",
        Slot::Retired17 => "RETIRED17",
        Slot::Retired18 => "RETIRED18",
        Slot::Retired19 => "RETIRED19",
        Slot::Retired20 => "RETIRED20",
        Slot::Attestation => "ATTESTATION",
    }
}

/// Convert SlotMetadata to JSON with integer enum values and public_key PEM.
fn metadata_to_json(metadata: &yubikit::piv::SlotMetadata) -> Value {
    let public_key_pem = SubjectPublicKeyInfoOwned::from_der(&metadata.public_key_der)
        .ok()
        .and_then(|spki| spki.to_pem(LineEnding::LF).ok());

    json!({
        "key_type": metadata.key_type as u8,
        "pin_policy": metadata.pin_policy as u8,
        "touch_policy": metadata.touch_policy as u8,
        "generated": metadata.generated,
        "public_key": public_key_pem,
    })
}

/// Check if a certificate's public key matches the slot metadata's public key.
fn public_key_match(cert_der: &[u8], metadata: &yubikit::piv::SlotMetadata) -> bool {
    let slot_spki = &metadata.public_key_der;

    // Get SPKI DER from certificate
    let cert = match Certificate::from_der(cert_der) {
        Ok(c) => c,
        Err(_) => return false,
    };
    let cert_spki = match cert.tbs_certificate.subject_public_key_info.to_der() {
        Ok(der) => der,
        Err(_) => return false,
    };

    slot_spki == &cert_spki
}
