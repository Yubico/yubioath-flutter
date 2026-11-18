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

#[cfg(test)]
mod tests {
    use super::*;
    use base64::{Engine, engine::general_purpose::STANDARD};
    use image::{GrayImage, ImageFormat, Luma};
    use std::io::Cursor;

    fn qr_image() -> GrayImage {
        let modules = [
            "111111101101001111111",
            "100000101001101000001",
            "101110101110101011101",
            "101110101111001011101",
            "101110100111001011101",
            "100000101011101000001",
            "111111101010101111111",
            "000000000000000000000",
            "110011100001100101111",
            "000110010000010011100",
            "001110101110000010010",
            "101010011011000110010",
            "010001110001110100010",
            "000000001101000110100",
            "111111100010010011110",
            "100000101000010010000",
            "101110101011000000011",
            "101110100010011010001",
            "101110100011010010000",
            "100000101011110000000",
            "111111101100100110001",
        ];
        let mut image = GrayImage::from_pixel(116, 116, Luma([255]));
        for (y, row) in modules.iter().enumerate() {
            for (x, module) in row.bytes().enumerate() {
                if module == b'1' {
                    for dy in 0..4 {
                        for dx in 0..4 {
                            image.put_pixel(
                                (x as u32 + 4) * 4 + dx,
                                (y as u32 + 4) * 4 + dy,
                                Luma([0]),
                            );
                        }
                    }
                }
            }
        }
        image
    }

    fn png_base64(image: GrayImage) -> String {
        let mut bytes = Cursor::new(Vec::new());
        image.write_to(&mut bytes, ImageFormat::Png).unwrap();
        STANDARD.encode(bytes.into_inner())
    }

    #[test]
    fn decodes_qr_image() {
        let data = png_base64(qr_image());
        assert_eq!(
            scan_qr(Some(&data)).unwrap().as_deref(),
            Some("yubioath-qr-test")
        );
    }

    #[test]
    fn blank_image_has_no_qr_code() {
        let data = png_base64(GrayImage::from_pixel(116, 116, Luma([255])));
        assert_eq!(scan_qr(Some(&data)).unwrap(), None);
    }

    #[test]
    fn truncated_qr_image_is_unreadable() {
        let image = qr_image();
        let truncated = image::imageops::crop_imm(&image, 0, 0, 116, 58).to_image();
        let data = png_base64(truncated);
        assert_eq!(scan_qr(Some(&data)).unwrap(), None);
    }

    #[test]
    fn rejects_invalid_base64() {
        assert_eq!(scan_qr(Some("%%%")), Err("invalid-image".to_string()));
    }

    #[test]
    fn rejects_non_image_data() {
        let data = STANDARD.encode(b"not an image");
        assert_eq!(scan_qr(Some(&data)), Err("invalid-image".to_string()));
    }
}
