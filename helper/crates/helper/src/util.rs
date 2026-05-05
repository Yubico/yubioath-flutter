use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use yubikit::core::Version;

/// Serialize a Version as a JSON array [major, minor, micro].
pub fn version_to_json(v: &Version) -> Value {
    json!([v.0, v.1, v.2])
}

/// Compute a short hex fingerprint from a string (first 16 hex chars of SHA-256).
pub fn id_from_fingerprint(fp: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(fp.as_bytes());
    let hash = hasher.finalize();
    hex::encode(&hash[..8])
}

/// Check if the current process is running as admin/root.
#[allow(dead_code)]
pub fn is_admin() -> bool {
    #[cfg(unix)]
    {
        unsafe { libc::getuid() == 0 }
    }
    #[cfg(windows)]
    {
        use std::mem::MaybeUninit;
        unsafe {
            let mut token = MaybeUninit::uninit();
            if windows_sys::Win32::Security::OpenProcessToken(
                windows_sys::Win32::System::Threading::GetCurrentProcess(),
                windows_sys::Win32::Security::TOKEN_QUERY,
                token.as_mut_ptr(),
            ) == 0
            {
                return false;
            }
            let token = token.assume_init();
            let mut elevation =
                MaybeUninit::<windows_sys::Win32::Security::TOKEN_ELEVATION>::uninit();
            let mut ret_len = 0u32;
            if windows_sys::Win32::Security::GetTokenInformation(
                token,
                windows_sys::Win32::Security::TokenElevation,
                elevation.as_mut_ptr() as *mut _,
                std::mem::size_of::<windows_sys::Win32::Security::TOKEN_ELEVATION>() as u32,
                &mut ret_len,
            ) == 0
            {
                return false;
            }
            elevation.assume_init().TokenIsElevated != 0
        }
    }
    #[cfg(not(any(unix, windows)))]
    {
        false
    }
}
