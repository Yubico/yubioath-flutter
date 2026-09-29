"""Local, permission-restricted diagnostics for hardware test runs."""

import json
import os
import shutil
import subprocess
import time
from collections import deque
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path


def _timestamp() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


class RunArtifacts:
    def __init__(self, root: Path, service_log: Path | None = None):
        started = datetime.now(timezone.utc)
        self.started = time.monotonic()
        self.path = root / f"{started:%Y%m%dT%H%M%S%f}-{os.getpid()}"
        self.path.mkdir(parents=True, mode=0o700)
        self.path.chmod(0o700)
        self.timeline = (self.path / "timeline.jsonl").open("x", encoding="utf-8")
        self.output = (self.path / "flutter.log").open("x", encoding="utf-8")
        self.test_events = self.path / "tests.jsonl"
        self.events = self.test_events.open("x", encoding="utf-8")
        self.app_log = self.path / "app.log"
        self.service_log = service_log
        self.service_stat = service_log.stat() if service_log is not None else None

    def event(self, event_type: str, **data: object) -> None:
        record = {
            "utc": _timestamp(),
            "elapsed_ms": round((time.monotonic() - self.started) * 1000),
            "event": event_type,
            **data,
        }
        self.timeline.write(json.dumps(record, default=str) + "\n")
        self.timeline.flush()

    @contextmanager
    def phase(self, name: str):
        started = time.monotonic()
        self.event("phase_start", phase=name)
        try:
            yield
        except BaseException as error:
            self.event(
                "phase_failed",
                phase=name,
                duration_ms=round((time.monotonic() - started) * 1000),
                error=str(error),
            )
            raise
        else:
            self.event(
                "phase_end",
                phase=name,
                duration_ms=round((time.monotonic() - started) * 1000),
            )

    def run_flutter(self, command: list[str]) -> int:
        with self.phase("flutter_test"):
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                errors="replace",
                bufsize=1,
            )
            if process.stdout is None:
                raise RuntimeError("Flutter test output was not captured")
            names: dict[int, str] = {}
            for line in process.stdout:
                self.output.write(f"{_timestamp()} {line}")
                self.output.flush()
                try:
                    item = json.loads(line)
                except json.JSONDecodeError:
                    item = None
                if isinstance(item, dict) and "type" in item:
                    self.events.write(line)
                    self.events.flush()
                    self._test_event(item, names)
                elif "TRAFFIC: " not in line:
                    if "Building " in line or "Running Gradle task" in line:
                        self.event("build_start", output=line.strip())
                    elif "✓ Built " in line or "Built build/" in line:
                        self.event("build_end", output=line.strip())
                    print(line, end="", flush=True)
            result = process.wait()
            self.event("flutter_exit", exit_code=result)
            return result

    def _test_event(self, item: dict, names: dict[int, str]) -> None:
        kind = item["type"]
        if kind == "testStart":
            test = item["test"]
            names[test["id"]] = test["name"]
            if not test.get("metadata", {}).get("skip"):
                self.event("test_start", name=test["name"], reporter_ms=item.get("time"))
                print(f"START {test['name']}", flush=True)
        elif kind == "testDone":
            name = names.get(item["testID"], str(item["testID"]))
            self.event(
                "test_end",
                name=name,
                result=item["result"],
                skipped=item.get("skipped", False),
                reporter_ms=item.get("time"),
            )
            if not item.get("hidden") and not item.get("skipped"):
                print(f"{item['result'].upper()} {name}", flush=True)
        elif kind == "error":
            name = names.get(item["testID"], str(item["testID"]))
            self.event(
                "test_error", name=name, error=item.get("error"),
                reporter_ms=item.get("time"),
            )
            print(f"ERROR {name}: {item.get('error')}\n{item.get('stackTrace', '')}", flush=True)
        elif kind == "print":
            message = item.get("message", "")
            if "TRAFFIC: " not in message:
                print(message, flush=True)
        elif kind == "done":
            self.event("reporter_done", success=item.get("success"))
        elif kind == "start":
            self.event("reporter_start")

    def finish(self, exit_code: int | None, error: BaseException | None = None) -> None:
        service_capture_error = None
        if self.service_log is not None:
            try:
                with self.service_log.open("rb") as source:
                    current = os.fstat(source.fileno())
                    if (current.st_dev, current.st_ino) == (
                        self.service_stat.st_dev, self.service_stat.st_ino,
                    ):
                        source.seek(self.service_stat.st_size)
                    else:
                        self.event("service_log_rotated", path=str(self.service_log))
                    with (self.path / "service.log").open("xb") as destination:
                        shutil.copyfileobj(source, destination)
            except OSError as capture_error:
                service_capture_error = (
                    f"Could not capture service log {self.service_log}: {capture_error}"
                )
                self.event("service_log_error", error=service_capture_error)
                print(service_capture_error, flush=True)
        self.event("run_end", exit_code=exit_code, error=str(error) if error else None)
        if exit_code != 0 or error is not None or service_capture_error:
            with (self.path / "failure.txt").open("x", encoding="utf-8") as report:
                report.write(
                    f"Exit code: {exit_code}\n"
                    f"Runner error: {error}\n"
                    f"Service capture error: {service_capture_error}\n"
                    f"Artifacts: {self.path}\n"
                    "See timeline.jsonl, tests.jsonl, flutter.log, app.log, "
                    "test-failures.jsonl, and service.log (when provided).\n"
                )
                for name in ("flutter.log", "app.log", "service.log", "test-failures.jsonl"):
                    file = self.path / name
                    if file.is_file():
                        with file.open(encoding="utf-8", errors="replace") as source:
                            tail = deque(source, maxlen=50)
                        report.write(f"\nLast {len(tail)} lines of {name}:\n")
                        report.writelines(tail)
        self.timeline.close()
        self.output.close()
        self.events.close()
