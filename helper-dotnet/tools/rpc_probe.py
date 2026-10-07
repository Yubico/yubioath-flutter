#!/usr/bin/env python3
"""Drive an Authenticator helper over its stdin/stdout JSON RPC and print a transcript.

Speaks the same wire protocol as lib/desktop/rpc.dart, so it works against both the
Python helper and the .NET helper. Used to capture golden responses and to diff the
two implementations.

Usage:
  rpc_probe.py HELPER_EXE SCRIPT.json [--out transcript.json]

SCRIPT.json is a list of steps:
  {"action": "get", "target": ["usb"], "body": {}}
Targets may contain "$serial", which is replaced with the first USB device id.
A step may set "signal_cancel_after": seconds to send a cancel signal.
"""

import json
import subprocess
import sys
import threading
import time


def main():
    exe, script_path = sys.argv[1], sys.argv[2]
    out = None
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]

    with open(script_path) as f:
        steps = json.load(f)

    proc = subprocess.Popen(
        [exe],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    logs = []
    threading.Thread(
        target=lambda: [logs.append(line.rstrip()) for line in proc.stderr],
        daemon=True,
    ).start()

    def send(msg):
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()

    transcript = []
    device_id = None
    for step in steps:
        target = [
            (device_id if t == "$serial" else t) for t in step.get("target", [])
        ]
        req = {
            "kind": "command",
            "action": step["action"],
            "target": target,
            "body": step.get("body", {}),
        }
        start = time.monotonic()
        send(req)
        cancel_after = step.get("signal_cancel_after")
        if cancel_after is not None:
            threading.Timer(
                cancel_after, lambda: send({"kind": "signal", "status": "cancel"})
            ).start()
        signals = []
        while True:
            line = proc.stdout.readline()
            if not line:
                resp = {"kind": "eof"}
                break
            resp = json.loads(line)
            if resp["kind"] == "signal":
                signals.append(resp)
                continue
            break
        elapsed = round((time.monotonic() - start) * 1000)
        if (
            device_id is None
            and resp.get("kind") == "success"
            and target == ["usb"]
            and step["action"] == "get"
        ):
            children = resp["body"].get("children", {})
            if children:
                device_id = next(iter(children))
        entry = {"request": req, "signals": signals, "response": resp, "ms": elapsed}
        transcript.append(entry)
        print(json.dumps(entry, indent=1, sort_keys=True))
        if resp["kind"] == "eof":
            break

    try:
        proc.stdin.write("\n")
        proc.stdin.close()
    except BrokenPipeError:
        pass
    proc.wait(timeout=10)
    if out:
        with open(out, "w") as f:
            json.dump({"transcript": transcript, "stderr": logs}, f, indent=1)


if __name__ == "__main__":
    main()
