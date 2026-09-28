//! Process-wide YubiKey device monitor.
//!
//! Wraps [`yubikit::platform::monitor::monitor_yubikeys`] to maintain a live
//! inventory of connected YubiKeys for as long as the helper process is
//! running. This replaces the previous polling-based approach of calling
//! `scan_usb_devices`/`list_devices` on every RPC request: the monitor keeps
//! an up-to-date view in the background via USB/PC/SC change notifications,
//! so callers can simply read the current inventory. See ykman-svc's
//! `device_manager.rs` for the analogous approach used there.

use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant};

use yubikit::core::Transport;
use yubikit::device::YubiKeyDevice;
use yubikit::management::{Capability, UsbInterface};
use yubikit::platform::device::LocalYubiKeyDevice;
use yubikit::platform::monitor::{
    DeviceNode, MonitorHandle, YubiKey, YubiKeyEvent, YubiKeyId, monitor_yubikeys,
};

/// How long to wait for the monitor's initial device enumeration to complete
/// before giving up and returning whatever has been discovered so far.
const READY_TIMEOUT: Duration = Duration::from_secs(3);

struct Monitor {
    inventory: Arc<Mutex<HashMap<YubiKeyId, (YubiKey, u64)>>>,
    revision: Arc<AtomicU64>,
    // Kept alive for the lifetime of the process; the monitor keeps running
    // in the background for as long as the helper is running.
    _handle: MonitorHandle,
}

static MONITOR: OnceLock<Monitor> = OnceLock::new();

/// Start the device monitor if it is not already running.
///
/// Safe to call repeatedly; the monitor is only started once.
fn ensure_started() -> &'static Monitor {
    MONITOR.get_or_init(|| {
        let inventory: Arc<Mutex<HashMap<YubiKeyId, (YubiKey, u64)>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let cb_inventory = Arc::clone(&inventory);
        let revision = Arc::new(AtomicU64::new(0));
        let cb_revision = Arc::clone(&revision);
        let interfaces = UsbInterface::CCID | UsbInterface::OTP | UsbInterface::FIDO;
        let handle = monitor_yubikeys(interfaces, move |event| {
            let mut inv = recover_lock(cb_inventory.lock());
            match event {
                YubiKeyEvent::Added(yk) | YubiKeyEvent::Changed(yk) => {
                    let next = cb_revision.fetch_add(1, Ordering::SeqCst) + 1;
                    inv.insert(yk.id(), (yk, next));
                }
                YubiKeyEvent::Removed(yk) => {
                    cb_revision.fetch_add(1, Ordering::SeqCst);
                    inv.remove(&yk.id());
                }
            }
        });
        log::info!("Device monitor started");

        // Block until the initial device enumeration completes so the
        // inventory is populated before the first caller queries it.
        if !handle.wait_ready(READY_TIMEOUT) {
            log::warn!("Device monitor initial scan did not complete within {READY_TIMEOUT:?}");
        }

        Monitor {
            inventory,
            revision,
            _handle: handle,
        }
    })
}

/// Returns a snapshot of the currently connected YubiKeys, ordered by stable
/// monitor id for deterministic naming.
pub fn devices() -> Vec<LocalYubiKeyDevice> {
    let monitor = ensure_started();
    let inv = recover_lock(monitor.inventory.lock());
    let mut items: Vec<(YubiKeyId, LocalYubiKeyDevice)> = inv
        .iter()
        .map(|(id, (yk, _))| (*id, yk.device().clone()))
        .collect();
    items.sort_by_key(|(id, _)| *id);
    items.into_iter().map(|(_, dev)| dev).collect()
}

/// Capture the monitor revision before writing a rebooting configuration.
pub fn reboot_marker() -> u64 {
    ensure_started().revision.load(Ordering::SeqCst)
}

fn interfaces_for(caps: Capability) -> UsbInterface {
    let mut ifaces = UsbInterface(0);
    if caps.contains(Capability::OTP) {
        ifaces = ifaces | UsbInterface::OTP;
    }
    if caps.contains(Capability::FIDO2) || caps.contains(Capability::U2F) {
        ifaces = ifaces | UsbInterface::FIDO;
    }
    if caps.contains(Capability::PIV)
        || caps.contains(Capability::OATH)
        || caps.contains(Capability::OPENPGP)
        || caps.contains(Capability::HSMAUTH)
    {
        ifaces = ifaces | UsbInterface::CCID;
    }
    ifaces
}

fn ready_after_reboot(
    yk: &YubiKey,
    revision: u64,
    marker: u64,
    serial: Option<u32>,
    expected_usb: Capability,
) -> bool {
    let dev = yk.device();
    let expected = interfaces_for(expected_usb);
    if revision <= marker
        || dev.info().serial != serial
        || dev.info().config.enabled_capabilities.get(&Transport::Usb) != Some(&expected_usb)
        || dev.usb_interfaces() != expected
    {
        return false;
    }
    (!expected.contains(UsbInterface::CCID)
        || yk.nodes().iter().any(|node| {
            matches!(node, DeviceNode::CardNode { reader_name, device_info }
                if dev.reader_name.as_ref() == Some(reader_name)
                    && device_info.config.enabled_capabilities.get(&Transport::Usb) == Some(&expected_usb))
        }))
        && (!expected.contains(UsbInterface::OTP) || dev.hid_path.is_some())
        && (!expected.contains(UsbInterface::FIDO) || dev.fido_path.is_some())
}

/// Wait for a post-write monitor update showing the new USB configuration and
/// all enabled interfaces ready, rather than accepting the pre-reboot snapshot.
///
/// Used after configuration changes that reboot the device, to wait for it
/// to come back before reporting success.
pub fn wait_for_serial(
    serial: Option<u32>,
    expected_usb: Option<Capability>,
    marker: u64,
    timeout: Duration,
) -> bool {
    let deadline = Instant::now() + timeout;
    loop {
        let monitor = ensure_started();
        let inv = recover_lock(monitor.inventory.lock());
        if let Some(expected_usb) = expected_usb {
            if inv.values().any(|(yk, revision)| {
                ready_after_reboot(yk, *revision, marker, serial, expected_usb)
            }) {
                return true;
            }
        } else if inv
            .values()
            .any(|(yk, revision)| *revision > marker && yk.serial() == serial)
        {
            return true;
        }
        drop(inv);
        if Instant::now() >= deadline {
            return false;
        }

        std::thread::sleep(Duration::from_millis(100));
    }
}

fn recover_lock<T>(result: std::sync::LockResult<T>) -> T {
    match result {
        Ok(guard) => guard,
        Err(poisoned) => {
            log::error!("Recovering poisoned device monitor inventory lock");
            poisoned.into_inner()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capabilities_map_to_expected_usb_interfaces() {
        assert_eq!(interfaces_for(Capability::PIV), UsbInterface::CCID);
        assert_eq!(
            interfaces_for(Capability::OTP | Capability::FIDO2),
            UsbInterface::OTP | UsbInterface::FIDO
        );
        assert_eq!(
            interfaces_for(Capability::OTP | Capability::OATH | Capability::U2F),
            UsbInterface::OTP | UsbInterface::CCID | UsbInterface::FIDO
        );
    }
}
