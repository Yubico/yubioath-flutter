# Windows service packaging

Both MSI installers consume the canonical service merge module from the pinned
`yubikit-rs` checkout. The Windows build artifacts carry its source and build
script in `service-module/`; the MSI jobs build it using the signed service
executable. The service lives outside either application's install directory
and stays installed and running until its last MSI consumer is removed.
Use matching architectures for the two MSI applications.

MSIX owns a separate `yubico-authenticator-svc` service, started with
`run --authenticator-msix`, and the matching
`\\.\pipe\yubico-authenticator-svc` named pipe. The helper selects that pipe from
its inherited Windows package identity. This allows MSI and MSIX installations
to coexist without sharing service ownership or deleting each other's service.
