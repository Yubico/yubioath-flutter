import io
import json
import stat
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from integration_test.run_artifacts import RunArtifacts


class RunArtifactsTests(unittest.TestCase):
    def test_records_live_test_events_and_phase_times(self):
        with tempfile.TemporaryDirectory() as directory:
            artifacts = RunArtifacts(Path(directory))
            records = [
                {"type": "testStart", "time": 120, "test": {"id": 1, "name": "Example"}},
                {"type": "print", "time": 150, "testID": 1, "message": "TRAFFIC: secret"},
                {
                    "type": "testDone", "time": 260, "testID": 1,
                    "result": "success", "skipped": False,
                },
                {"type": "done", "time": 270, "success": True},
            ]
            with patch("integration_test.run_artifacts.subprocess.Popen") as popen:
                process = popen.return_value
                process.stdout = io.StringIO(
                    "Building application...\n"
                    "✓ Built build/linux/x64/debug/bundle/authenticator\n"
                    + "".join(json.dumps(record) + "\n" for record in records)
                )
                process.wait.return_value = 0
                with artifacts.phase("device_discovery"):
                    pass
                self.assertEqual(artifacts.run_flutter(["flutter", "test"]), 0)
            artifacts.finish(0)

            timeline = [
                json.loads(line)
                for line in (artifacts.path / "timeline.jsonl").read_text().splitlines()
            ]
            self.assertEqual(
                [entry["event"] for entry in timeline if entry["event"].startswith("test_")],
                ["test_start", "test_end"],
            )
            self.assertEqual(
                next(entry for entry in timeline if entry["event"] == "test_end")["name"],
                "Example",
            )
            self.assertIn("build_start", [entry["event"] for entry in timeline])
            self.assertIn("build_end", [entry["event"] for entry in timeline])
            self.assertEqual(
                len((artifacts.path / "tests.jsonl").read_text().splitlines()), 4
            )
            self.assertIn("TRAFFIC: secret", (artifacts.path / "flutter.log").read_text())
            self.assertFalse((artifacts.path / "failure.txt").exists())
            self.assertEqual(stat.S_IMODE(artifacts.path.stat().st_mode), 0o700)

    def test_failure_keeps_original_service_log_delta_and_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "daemon.log"
            service.write_text("previous run\n")
            artifacts = RunArtifacts(root, service)
            with service.open("a") as log:
                log.write("new traffic\n")
            artifacts.output.write("Flutter error\n")
            artifacts.output.flush()
            artifacts.finish(1, RuntimeError("fixture failed"))

            self.assertEqual((artifacts.path / "service.log").read_text(), "new traffic\n")
            report = (artifacts.path / "failure.txt").read_text()
            self.assertIn("fixture failed", report)
            self.assertIn("Flutter error", report)
            self.assertIn("new traffic", report)

    def test_rotated_service_log_captures_new_file_from_start(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "daemon.log"
            service.write_text("previous run was much longer\n")
            artifacts = RunArtifacts(root, service)
            service.rename(root / "daemon.log.1")
            service.write_text("new log\n")
            artifacts.finish(0)

            self.assertEqual((artifacts.path / "service.log").read_text(), "new log\n")
            self.assertIn(
                '"event": "service_log_rotated"',
                (artifacts.path / "timeline.jsonl").read_text(),
            )

    def test_missing_service_log_does_not_hide_original_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root / "daemon.log"
            service.write_text("previous run\n")
            artifacts = RunArtifacts(root, service)
            service.unlink()
            artifacts.finish(1, RuntimeError("original failure"))

            report = (artifacts.path / "failure.txt").read_text()
            self.assertIn("original failure", report)
            self.assertIn("Could not capture service log", report)
            self.assertIn(
                '"event": "service_log_error"',
                (artifacts.path / "timeline.jsonl").read_text(),
            )

    def test_failed_test_records_error_and_device_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            artifacts = RunArtifacts(Path(directory))
            records = [
                {"type": "testStart", "test": {"id": 3, "name": "Failing test"}},
                {"type": "error", "testID": 3, "error": "assertion failed", "stackTrace": "frame"},
                {"type": "testDone", "testID": 3, "result": "failure"},
                {"type": "done", "success": False},
            ]
            with patch("integration_test.run_artifacts.subprocess.Popen") as popen:
                process = popen.return_value
                process.stdout = io.StringIO(
                    "".join(json.dumps(record) + "\n" for record in records)
                )
                process.wait.return_value = 1
                self.assertEqual(artifacts.run_flutter(["flutter", "test"]), 1)
            (artifacts.path / "test-failures.jsonl").write_text(
                '{"test":"Failing test","device":{"serial":123},"error":"assertion failed"}\n'
            )
            artifacts.finish(1)

            report = (artifacts.path / "failure.txt").read_text()
            self.assertIn("test-failures.jsonl", report)
            self.assertIn('"serial":123', report)
            self.assertIn("assertion failed", report)
            self.assertIn(
                '"event": "test_error"',
                (artifacts.path / "timeline.jsonl").read_text(),
            )


if __name__ == "__main__":
    unittest.main()
