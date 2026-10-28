import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import BadZipFile, ZipFile

from extract_signed_zip import extract_flat


class ExtractSignedZipTests(unittest.TestCase):
    def test_flattens_absolute_paths(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "1.zip"
            output = root / "signed"
            output.mkdir()
            with ZipFile(archive, "w") as zip_file:
                zip_file.writestr(
                    "/scribe/bundle/helper/authenticator-helper.exe", b"helper"
                )
                zip_file.writestr("/scribe/bundle/ykman-svc.exe", b"service")

            extract_flat(archive, output)

            self.assertEqual(
                (output / "authenticator-helper.exe").read_bytes(), b"helper"
            )
            self.assertEqual((output / "ykman-svc.exe").read_bytes(), b"service")
            self.assertEqual(
                sorted(path.name for path in output.iterdir()),
                [
                    "authenticator-helper.exe",
                    "ykman-svc.exe",
                ],
            )

    def test_rejects_duplicate_basenames(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "1.zip"
            output = root / "signed"
            output.mkdir()
            with ZipFile(archive, "w") as zip_file:
                zip_file.writestr("/scribe/first/app.exe", b"one")
                zip_file.writestr("/scribe/second/app.exe", b"two")

            with self.assertRaisesRegex(ValueError, "Duplicate"):
                extract_flat(archive, output)
            self.assertEqual(list(output.iterdir()), [])

    def test_rejects_empty_and_invalid_archives(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "1.zip"
            output = root / "signed"
            output.mkdir()
            with ZipFile(archive, "w"):
                pass

            with self.assertRaisesRegex(ValueError, "No signed files"):
                extract_flat(archive, output)

            archive.write_bytes(b"not a zip")
            with self.assertRaises(BadZipFile):
                extract_flat(archive, output)


if __name__ == "__main__":
    unittest.main()
