import unittest
from contextlib import redirect_stdout
from io import StringIO
from subprocess import CompletedProcess
from unittest.mock import patch

from cargo_deny import ROOT, TARGETS, main


class CargoDenyTests(unittest.TestCase):
    @patch("cargo_deny.subprocess.run")
    def test_checks_every_supported_target_with_locked_helper_policy(self, run):
        run.return_value = CompletedProcess([], 0)
        with redirect_stdout(StringIO()):
            self.assertEqual(main(), 0)
        self.assertEqual(
            set(TARGETS),
            {
                "x86_64-unknown-linux-gnu",
                "aarch64-unknown-linux-gnu",
                "x86_64-apple-darwin",
                "aarch64-apple-darwin",
                "x86_64-pc-windows-msvc",
                "aarch64-pc-windows-msvc",
            },
        )
        self.assertEqual(run.call_count, 6)
        for call, target in zip(run.call_args_list, TARGETS):
            self.assertEqual(
                call.args,
                (
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
                ),
            )
            self.assertEqual(call.kwargs, {"cwd": ROOT, "check": False})

    @patch("cargo_deny.subprocess.run")
    def test_reports_failure_and_still_checks_remaining_targets(self, run):
        run.side_effect = [CompletedProcess([], code) for code in (0, 1, 0, 2, 0, 1)]
        with redirect_stdout(StringIO()):
            self.assertEqual(main(), 1)
        self.assertEqual(run.call_count, 6)

    @patch("cargo_deny.subprocess.run", side_effect=FileNotFoundError("missing cargo"))
    def test_does_not_hide_missing_tools(self, run):
        with (
            redirect_stdout(StringIO()),
            self.assertRaisesRegex(FileNotFoundError, "missing cargo"),
        ):
            main()
        run.assert_called_once()


if __name__ == "__main__":
    unittest.main()
