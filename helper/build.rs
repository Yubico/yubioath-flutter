use std::env;

fn main() {
    if env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }

    // Windows Installer only replaces an existing versioned file with one of
    // an equal or higher version, so the helper must carry the app version.
    let part = |name: &str| -> u64 {
        env::var(name)
            .unwrap()
            .parse::<u16>()
            .unwrap_or_else(|_| panic!("{name} must fit in 16 bits"))
            .into()
    };
    let version = (part("CARGO_PKG_VERSION_MAJOR") << 48)
        | (part("CARGO_PKG_VERSION_MINOR") << 32)
        | (part("CARGO_PKG_VERSION_PATCH") << 16);

    let mut res = winresource::WindowsResource::new();
    res.set("CompanyName", "Yubico");
    res.set("FileDescription", "Yubico Authenticator Helper");
    res.set("LegalCopyright", "Copyright Yubico AB. Apache-2.0");
    res.set("OriginalFilename", "authenticator-helper.exe");
    res.set("ProductName", "Yubico Authenticator");
    res.set_version_info(winresource::VersionInfo::FILEVERSION, version);
    res.set_version_info(winresource::VersionInfo::PRODUCTVERSION, version);
    res.compile().expect("Failed to compile Windows resources");
}
