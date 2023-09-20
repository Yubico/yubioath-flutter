# -*- mode: python ; coding: utf-8 -*-
import sys
import subprocess


block_cipher = None


a = Analysis(
    ["authenticator-helper.py"],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

target_arch = None
# MacOS: If the running Python process is "universal", build a univeral2 binary.
if sys.platform == "darwin":
    r = subprocess.run(['lipo', '-archs', sys.executable], capture_output=True).stdout
    if b"x86_64" in r and b"arm64" in r:
        target_arch = "universal2"

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="authenticator-helper",
    icon="NONE",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    manifest="authenticator-helper.exe.manifest",
    version="version_info.txt",
    disable_windowed_traceback=False,
    target_arch=target_arch,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="helper",
)
