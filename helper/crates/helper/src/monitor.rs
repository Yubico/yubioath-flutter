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
use std::sync::{Arc, Mutex, OnceLock};
use std::time::{Duration, Instant};

use yubikit::management::UsbInterface;
use yubikit::platform::device::LocalYubiKeyDevice;
use yubikit::platform::monitor::{MonitorHandle, YubiKeyEvent, YubiKeyId, monitor_yubikeys};

/// How long to wait for the monitor's initial device enumeration to complete
/// before giving up and returning whatever has been discovered so far.
const READY_TIMEOUT: Duration = Duration::from_secs(3);

struct Monitor {
    inventory: Arc<Mutex<HashMap<YubiKeyId, LocalYubiKeyDevice>>>,
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
        let inventory: Arc<Mutex<HashMap<YubiKeyId, LocalYubiKeyDevice>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let cb_inventory = Arc::clone(&inventory);
        let interfaces = UsbInterface::CCID | UsbInterface::OTP | UsbInterface::FIDO;
        let handle = monitor_yubikeys(interfaces, move |event| {
            let mut inv = recover_lock(cb_inventory.lock());
            match event {
                YubiKeyEvent::Added(yk) | YubiKeyEvent::Changed(yk) => {
                    inv.insert(yk.id(), yk.into_device());
                }
                YubiKeyEvent::Removed(yk) => {
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
            _handle: handle,
        }
    })
}

/// Returns a snapshot of the currently connected YubiKeys, ordered by stable
/// monitor id for deterministic naming.
pub fn devices() -> Vec<LocalYubiKeyDevice> {
    let monitor = ensure_started();
    let inv = recover_lock(monitor.inventory.lock());
    let mut items: Vec<(YubiKeyId, LocalYubiKeyDevice)> =
        inv.iter().map(|(id, dev)| (*id, dev.clone())).collect();
    items.sort_by_key(|(id, _)| *id);
    items.into_iter().map(|(_, dev)| dev).collect()
}

/// Wait for a device with the given serial to (re)appear in the monitored
/// inventory, or until `timeout` elapses. Returns `true` if found.
///
/// Used after configuration changes that reboot the device, to wait for it
/// to come back before reporting success.
pub fn wait_for_serial(serial: Option<u32>, timeout: Duration) -> bool {
    let deadline = Instant::now() + timeout;
    loop {
        if devices().iter().any(|d| d.info().serial == serial) {
            return true;
        }
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
