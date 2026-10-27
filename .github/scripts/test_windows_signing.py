import json
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZipFile

from extract_signed_zip import extract_flat
from windows_signing import ARCHITECTURES, prepare, restore


class WindowsSigningTests(unittest.TestCase):
    def create_artifact(self, root, architecture, kind):
        arch = architecture["arch"]
        if kind == "binaries":
            artifact = root / f"yubioath-desktop-windows{architecture['suffix']}"
            bundle = artifact / f"yubioath-desktop-7.5.0-rc.1-windows{architecture['suffix']}"
            inputs = [
                artifact / "ykman-svc.exe",
                bundle / "authenticator.exe",
                bundle / "helper/authenticator-helper.exe",
                bundle / "plugin.dll",
            ]
            bundle.mkdir(parents=True)
            (bundle / "unsigned-data.txt").write_text("unchanged")
        else:
            artifact = root / f"installer{architecture['artifact-suffix']}"
            inputs = [artifact / f"yubioath-desktop{architecture['suffix']}.msi"]
        for path in inputs:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(f"{arch}:{path.name}".encode())
        return inputs

    def test_round_trip_both_and_either_architecture(self):
        for kind in ("binaries", "installers"):
            for architectures in (ARCHITECTURES, ARCHITECTURES[:1], ARCHITECTURES[1:]):
                with self.subTest(kind=kind, architectures=architectures):
                    with TemporaryDirectory() as directory:
                        root = Path(directory)
                        artifacts = root / "artifacts"
                        inputs = []
                        for architecture in architectures:
                            inputs.extend(
                                self.create_artifact(artifacts, architecture, kind)
                            )
                        original = {path: path.read_bytes() for path in inputs}
                        staging = root / "signing-input"
                        script = Path(__file__).with_name("windows_signing.py")
                        output = subprocess.check_output(
                            [
                                sys.executable, str(script), "prepare", kind,
                                str(artifacts), str(staging),
                            ],
                            text=True,
                        )
                        outputs = dict(
                            line.split("=", 1) for line in output.splitlines()
                        )
                        self.assertEqual(
                            json.loads(outputs["matrix"]), {"include": architectures}
                        )
                        self.assertEqual(
                            json.loads(outputs["architectures"]),
                            [item["arch"] for item in architectures],
                        )
                        archive = root / "1.zip"
                        with ZipFile(archive, "w") as zip_file:
                            for path in (staging / "files").iterdir():
                                zip_file.writestr(
                                    f"/scribe/signing-input/files/{path.name}",
                                    b"signed:" + path.read_bytes(),
                                )
                        signed = root / "signed"
                        signed.mkdir()
                        extract_flat(archive, signed)
                        subprocess.run(
                            [
                                sys.executable, str(script), "restore",
                                str(artifacts), str(staging), str(signed),
                            ],
                            check=True,
                        )
                        for path in inputs:
                            self.assertEqual(
                                path.read_bytes(), b"signed:" + original[path]
                            )
                        for path in artifacts.rglob("unsigned-data.txt"):
                            self.assertEqual(path.read_text(), "unchanged")

    def test_rejects_missing_artifacts(self):
        for kind in ("binaries", "installers"):
            with self.subTest(kind=kind), TemporaryDirectory() as directory:
                root = Path(directory)
                with self.assertRaisesRegex(ValueError, "No .* artifacts"):
                    prepare(kind, root / "missing", root / "staging")
                self.assertFalse((root / "staging").exists())

    def test_rejects_incomplete_artifact(self):
        for kind in ("binaries", "installers"):
            with self.subTest(kind=kind), TemporaryDirectory() as directory:
                root = Path(directory)
                inputs = self.create_artifact(
                    root / "artifacts", ARCHITECTURES[0], kind
                )
                inputs[0].unlink()
                with self.assertRaisesRegex(ValueError, "Missing"):
                    prepare(kind, root / "artifacts", root / "staging")
                self.assertFalse((root / "staging").exists())

    def test_rejects_duplicate_names_within_architecture(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            inputs = self.create_artifact(
                root / "artifacts", ARCHITECTURES[0], "binaries"
            )
            duplicate = inputs[1].parent / "nested/authenticator.exe"
            duplicate.parent.mkdir()
            duplicate.write_bytes(b"duplicate")
            with self.assertRaisesRegex(ValueError, "Duplicate"):
                prepare("binaries", root / "artifacts", root / "staging")

    def test_rejects_missing_and_unexpected_signed_files_before_replacing(self):
        for mismatch in ("missing", "unexpected"):
            with self.subTest(mismatch=mismatch), TemporaryDirectory() as directory:
                root = Path(directory)
                inputs = self.create_artifact(
                    root / "artifacts", ARCHITECTURES[0], "binaries"
                )
                original = {path: path.read_bytes() for path in inputs}
                prepare("binaries", root / "artifacts", root / "staging")
                signed = root / "signed"
                signed.mkdir()
                for path in (root / "staging/files").iterdir():
                    (signed / path.name).write_bytes(b"signed")
                if mismatch == "missing":
                    next(signed.iterdir()).unlink()
                else:
                    (signed / "unexpected.exe").write_bytes(b"unexpected")
                with self.assertRaisesRegex(ValueError, "do not match"):
                    restore(root / "artifacts", root / "staging", signed)
                self.assertEqual({path: path.read_bytes() for path in inputs}, original)


if __name__ == "__main__":
    unittest.main()
