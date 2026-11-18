#!/usr/bin/env python3
"""Check dependency policy separately for each supported desktop target."""

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TARGETS = (
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
    "x86_64-pc-windows-msvc",
    "aarch64-pc-windows-msvc",
)


def main() -> int:
    failed = False
    for target in TARGETS:
        print(f"Checking helper dependencies for {target}", flush=True)
        result = subprocess.run(
            [
                "cargo",
                "deny",
                "--manifest-path",
                "helper/Cargo.toml",
                "--locked",
                "--config",
                "helper/deny.toml",
                "--target",
                target,
                "check",
            ],
            cwd=ROOT,
            check=False,
        )
        if result.returncode != 0:
            failed = True
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
