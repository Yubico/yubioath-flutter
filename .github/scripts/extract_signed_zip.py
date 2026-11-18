"""Flatten a Scribe ZIP containing absolute paths to signed files."""

from pathlib import Path, PurePosixPath
from shutil import copyfileobj
from sys import argv
from zipfile import ZipFile


def extract_flat(archive_path: Path, output_dir: Path) -> None:
    with ZipFile(archive_path) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        if not entries:
            raise ValueError(f"No signed files in {archive_path}")

        names = [PurePosixPath(entry.filename).name for entry in entries]
        if any(not name or name in {".", ".."} for name in names):
            raise ValueError(f"Invalid file name in {archive_path}")
        if len(names) != len(set(names)):
            raise ValueError(f"Duplicate signed file names in {archive_path}")

        for entry, name in zip(entries, names):
            with (
                archive.open(entry) as source,
                (output_dir / name).open("xb") as target,
            ):
                copyfileobj(source, target)


if __name__ == "__main__":
    if len(argv) != 3:
        raise SystemExit("Usage: extract_signed_zip.py ARCHIVE OUTPUT_DIR")
    extract_flat(Path(argv[1]), Path(argv[2]))
