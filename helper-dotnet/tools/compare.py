#!/usr/bin/env python3
"""Compare two rpc_probe transcripts (Python helper vs .NET helper) step by step.

Usage: compare.py PYTHON.json DOTNET.json [--ignore key1,key2]

Reports, per step: response kind/status mismatches, keys missing on either side, and value
differences. Values that legitimately change between runs (state hashes, codes, timestamps,
encrypted identifiers) are ignored by default.
"""

import json
import sys

DEFAULT_IGNORE = {
    "state",
    "time",
    "enc_identifier",
    "enc_cred_store_state",
    "value",
    "valid_from",
    "valid_to",
    "message",
}


def walk(a, b, path, out, ignore):
    if path and path[-1] in ignore:
        return
    # Root node reports the helper's own version string (ykman version vs .NET helper version).
    if path and path[-1] == "version" and isinstance(a, str):
        return
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            p = path + [k]
            if k not in b:
                if k not in ignore:
                    out.append(("missing-in-dotnet", p, a[k], None))
            elif k not in a:
                if k not in ignore:
                    out.append(("extra-in-dotnet", p, None, b[k]))
            else:
                walk(a[k], b[k], p, out, ignore)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            out.append(("list-length", path, len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)):
            walk(x, y, path + [str(i)], out, ignore)
    elif a != b:
        out.append(("value", path, a, b))


def main():
    py = json.load(open(sys.argv[1]))["transcript"]
    net = json.load(open(sys.argv[2]))["transcript"]
    ignore = set(DEFAULT_IGNORE)
    if "--ignore" in sys.argv:
        ignore |= set(sys.argv[sys.argv.index("--ignore") + 1].split(","))

    total = 0
    for i, (a, b) in enumerate(zip(py, net)):
        req = a["request"]
        label = f"#{i} {req['action']} {'/'.join(req['target'])}"
        diffs = []
        walk(a["response"], b["response"], [], diffs, ignore)
        sa = [s["status"] for s in a.get("signals", [])]
        sb = [s["status"] for s in b.get("signals", [])]
        if sa != sb:
            diffs.append(("signals", [], sa, sb))
        status = "OK  " if not diffs else "DIFF"
        print(f"{status} {label}")
        for kind, path, x, y in diffs:
            total += 1
            print(f"      {kind:18} {'.'.join(path) or '<root>'}: python={json.dumps(x)[:120]} dotnet={json.dumps(y)[:120]}")
    if len(py) != len(net):
        print(f"step count differs: python={len(py)} dotnet={len(net)}")
        total += 1
    print(f"\n{total} difference(s)")
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
