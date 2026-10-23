import os
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch

from click.testing import CliRunner

sys.path.insert(0, str(Path(__file__).parent))
import runner
from run_artifacts import RunArtifacts


@dataclass
class DeviceInfo:
    serial: int


class RunnerOptionsTests(unittest.TestCase):
    def test_controller_verification_reads_native_device_info(self):
        pico = Mock(port=6)
        device = SimpleNamespace(info=DeviceInfo(123456))
        with (
            patch.object(runner, "list_all_devices", side_effect=[[], [device], [device]]),
            patch.object(runner.time, "sleep"),
        ):
            runner.verify_controller(pico, 123456)
        pico.remove.assert_called_once_with()
        pico.restore.assert_called_once_with()

    def test_manual_flags_preserve_explicit_and_unspecified_values(self):
        with tempfile.TemporaryDirectory() as directory:
            for controller in ([], ["--controller", "http://example.test"]):
                for option, expected in (
                    ([], None),
                    (["--manual"], True),
                    (["--no-manual"], False),
                ):
                    with self.subTest(controller=controller, option=option):
                        previous_umask = os.umask(0o077)
                        os.umask(previous_umask)
                        try:
                            with patch.object(runner, "_run_tests", return_value=0) as run:
                                result = CliRunner().invoke(
                                    runner.main,
                                    ["--artifacts-dir", directory, *controller, *option],
                                )
                        finally:
                            os.umask(previous_umask)
                        self.assertEqual(result.exit_code, 0, result.output)
                        self.assertIs(run.call_args.args[6], expected)

    def test_manual_filter_with_and_without_controller(self):
        cases = (
            (False, None, ["--exclude-tags", "manual"]),
            (False, True, ["--tags", "manual"]),
            (False, False, ["--exclude-tags", "manual"]),
            (True, None, []),
            (True, True, ["--tags", "manual"]),
            (True, False, ["--exclude-tags", "manual"]),
        )
        with tempfile.TemporaryDirectory() as directory:
            for has_controller, manual, tags in cases:
                with self.subTest(controller=has_controller, manual=manual):
                    artifacts = RunArtifacts(Path(directory))
                    controller = "http://example.test" if has_controller else None
                    try:
                        with (
                            patch.object(runner, "list_all_devices", return_value=[
                                SimpleNamespace(pid=123, info=DeviceInfo(123456))
                            ]),
                            patch.object(runner, "verify_controller"),
                            patch.object(runner.PicoController, "restore"),
                            patch.object(runner.click, "confirm", return_value=True),
                            patch.object(artifacts, "run_flutter", return_value=0) as run,
                        ):
                            result = runner._run_tests(
                                "123456" if has_controller else None,
                                None, None, None, None, not has_controller,
                                manual, controller, 6, False,
                                (runner.App.management,), artifacts,
                            )
                            command = run.call_args.args[0]
                    finally:
                        artifacts.finish(0)
                    self.assertEqual(result, 0)
                    self.assertEqual(
                        [arg for arg in command if arg in ("--tags", "--exclude-tags", "manual")],
                        tags,
                    )

    def test_reader_selection_uses_native_device_info(self):
        device = SimpleNamespace(
            pid=123, reader_name="Test NFC Reader", info=DeviceInfo(123456)
        )
        with tempfile.TemporaryDirectory() as directory:
            artifacts = RunArtifacts(Path(directory))
            try:
                with (
                    patch.object(runner, "list_all_devices", return_value=[device]) as discover,
                    patch.object(runner.click, "confirm", return_value=True),
                    patch.object(artifacts, "run_flutter", return_value=0) as run,
                ):
                    result = runner._run_tests(
                        "123456", "nfc reader", None, None, None, False,
                        False, None, 6, False, (runner.App.management,), artifacts,
                    )
                self.assertEqual(result, 0)
                discover.assert_called_once_with([runner.SmartCardConnection])
                self.assertIn("--dart-define=READER=nfc reader", run.call_args.args[0])
            finally:
                artifacts.finish(0)


if __name__ == "__main__":
    unittest.main()
