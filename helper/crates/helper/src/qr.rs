use image::RgbaImage;

/// Scan a QR code from either a base64-encoded image or a screenshot.
/// Returns the decoded text, or None if no QR code was found.
pub fn scan_qr(image_data: Option<&str>) -> Result<Option<String>, String> {
    let img = if let Some(data) = image_data {
        decode_base64_image(data)?
    } else {
        capture_screen()?
    };

    let gray = image::DynamicImage::ImageRgba8(img).into_luma8();
    decode_qr(&gray)
}

fn decode_base64_image(data: &str) -> Result<RgbaImage, String> {
    use base64::Engine;
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(data)
        .map_err(|_| "invalid-image".to_string())?;
    let img = image::load_from_memory(&bytes).map_err(|_| "invalid-image".to_string())?;
    Ok(img.into_rgba8())
}

#[cfg(not(target_os = "linux"))]
fn capture_screen() -> Result<RgbaImage, String> {
    let monitors = xcap::Monitor::all().map_err(|e| format!("Failed to list monitors: {e}"))?;
    let monitor = monitors
        .into_iter()
        .find(|m| m.is_primary().unwrap_or(false))
        .or_else(|| xcap::Monitor::all().ok().and_then(|m| m.into_iter().next()))
        .ok_or_else(|| "No monitors found".to_string())?;

    monitor
        .capture_image()
        .map_err(|e| format!("Failed to capture screenshot: {e}"))
}

#[cfg(target_os = "linux")]
fn capture_screen() -> Result<RgbaImage, String> {
    use std::process::Command;

    let tmp = std::env::temp_dir().join(format!("qr_capture_{}.png", std::process::id()));
    let tmp_path = tmp.to_str().ok_or("Invalid temp path")?;

    // Restore original LD_LIBRARY_PATH if it was overridden (e.g., by PyInstaller)
    let mut env_override = Vec::new();
    if let Ok(orig) = std::env::var("LD_LIBRARY_PATH_ORIG") {
        env_override.push(("LD_LIBRARY_PATH", orig));
    }

    // Try gnome-screenshot
    let result = Command::new("gnome-screenshot")
        .args(["-f", tmp_path])
        .envs(env_override.iter().map(|(k, v)| (*k, v.as_str())))
        .status();

    if let Ok(status) = result
        && status.success()
    {
        let img = image::open(&tmp)
            .map_err(|e| format!("Failed to open screenshot: {e}"))?
            .into_rgba8();
        let _ = std::fs::remove_file(&tmp);
        return Ok(img);
    }

    // Try spectacle (KDE)
    let result = Command::new("spectacle")
        .args(["-b", "-n", "-o", tmp_path])
        .envs(env_override.iter().map(|(k, v)| (*k, v.as_str())))
        .status();

    if let Ok(status) = result
        && status.success()
    {
        let img = image::open(&tmp)
            .map_err(|e| format!("Failed to open screenshot: {e}"))?
            .into_rgba8();
        let _ = std::fs::remove_file(&tmp);
        return Ok(img);
    }

    // Try grim (Wayland/Sway)
    let result = Command::new("grim")
        .args([tmp_path])
        .envs(env_override.iter().map(|(k, v)| (*k, v.as_str())))
        .status();

    if let Ok(status) = result
        && status.success()
    {
        let img = image::open(&tmp)
            .map_err(|e| format!("Failed to open screenshot: {e}"))?
            .into_rgba8();
        let _ = std::fs::remove_file(&tmp);
        return Ok(img);
    }

    let _ = std::fs::remove_file(&tmp);
    Err("Unable to capture screenshot".to_string())
}

fn decode_qr(gray: &image::GrayImage) -> Result<Option<String>, String> {
    let mut prepared = rqrr::PreparedImage::prepare(gray.clone());
    let grids = prepared.detect_grids();
    for grid in grids {
        if let Ok((_, content)) = grid.decode() {
            return Ok(Some(content));
        }
    }
    Ok(None)
}
