"""Stage architecture-qualified Scribe inputs and restore their signed outputs."""

import argparse
import json
from pathlib import Path
from shutil import copyfile

ARCHITECTURES = [
    {"arch": "x64", "suffix": "", "artifact-suffix": ""},
    {
        "arch": "arm64",
        "suffix": "-arm64",
        "artifact-suffix": "-windows-arm64",
    },
]


def prepare(kind: str, artifacts: Path, staging: Path) -> list[dict[str, str]]:
    files = {}
    available = []
    for architecture in ARCHITECTURES:
        if kind == "binaries":
            artifact = artifacts / f"yubioath-desktop-windows{architecture['suffix']}"
            candidates = sorted(
                path
                for path in artifact.rglob("*")
                if path.is_file() and path.suffix.lower() in {".exe", ".dll"}
            )
        else:
            artifact = artifacts / f"installer{architecture['artifact-suffix']}"
            candidates = [artifact / f"yubioath-desktop{architecture['suffix']}.msi"]
        if not artifact.is_dir():
            continue
        if kind == "binaries" and not {
            "authenticator.exe",
            "authenticator-helper.exe",
            "ykman-svc.exe",
        }.issubset(path.name for path in candidates):
            raise ValueError(f"Missing required executables in {artifact}")
        for path in candidates:
            if not path.is_file():
                raise ValueError(f"Missing signing input: {path}")
            name = f"{architecture['arch']}-{path.name}"
            if name in files:
                raise ValueError(f"Duplicate signing input: {name}")
            files[name] = path.relative_to(artifacts).as_posix()
        available.append(architecture)
    if not available:
        raise ValueError(f"No {kind} artifacts available in {artifacts}")

    destination = staging / "files"
    destination.mkdir(parents=True, exist_ok=False)
    for name, relative_path in files.items():
        copyfile(artifacts / relative_path, destination / name)
    (staging / "manifest.json").write_text(json.dumps(files, indent=2))
    return available


def restore(artifacts: Path, staging: Path, signed: Path) -> None:
    files = json.loads((staging / "manifest.json").read_text())
    actual = {path.name for path in signed.iterdir() if path.is_file()}
    if actual != files.keys():
        raise ValueError(
            f"Signed files do not match submission: "
            f"missing={sorted(files.keys() - actual)}, "
            f"unexpected={sorted(actual - files.keys())}"
        )
    for relative_path in files.values():
        if not (artifacts / relative_path).is_file():
            raise ValueError(f"Missing original signing input: {relative_path}")
    for name, relative_path in files.items():
        copyfile(signed / name, artifacts / relative_path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    prepare_parser = commands.add_parser("prepare")
    prepare_parser.add_argument("kind", choices=["binaries", "installers"])
    prepare_parser.add_argument("artifacts", type=Path)
    prepare_parser.add_argument("staging", type=Path)
    restore_parser = commands.add_parser("restore")
    restore_parser.add_argument("artifacts", type=Path)
    restore_parser.add_argument("staging", type=Path)
    restore_parser.add_argument("signed", type=Path)
    args = parser.parse_args()
    if args.command == "prepare":
        available = prepare(args.kind, args.artifacts, args.staging)
        print(f"architectures={json.dumps([item['arch'] for item in available])}")
    else:
        restore(args.artifacts, args.staging, args.signed)


if __name__ == "__main__":
    main()
