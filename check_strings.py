#!/usr/bin/env python3

#  Copyright (C) 2023 Yubico.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


import json
import os
import sys

errors = []


def check_duplicate_keys(pairs):
    seen = set()
    for d in [k for k, v in pairs if k in seen or seen.add(k)]:
        errors.append(f"Duplicate key: {d}")
    return dict(pairs)


def check_duplicate_values(strings):
    seen = {}
    for k, v in strings.items():
        if isinstance(v, str):
            if v in seen:
                errors.append(
                    f"Duplicate value in key: {k} (originally in {seen[v]}): {v}"
                )
            else:
                seen[v] = k


def check_prefixes(k, v, s_max_words, s_max_len):
    errs = []
    if k.startswith("s_"):
        if len(v) > s_max_len:
            errs.append(f"Too long ({len(v)} chars)")
        if len(v.split()) > s_max_words:
            errs.append(f"Too many words ({len(v.split())})")
    if k.startswith("l_") or k.startswith("s_"):
        if v.endswith("."):
            errs.append("Ends with '.'")
        if ". " in v:
            errs.append("Spans multiple sentences")
    elif k.startswith("p_"):
        if v[-1] not in ".!":
            errs.append("Doesn't end in punctuation")
    elif k.startswith("q_"):
        if not v.endswith("?"):
            errs.append("Doesn't end in '?'")
    return errs


def check_misc(k, v):
    errs = []
    if "..." in v:
        errs.append("'...' should be replaced with '\\u2026'")
    if v[0].upper() != v[0]:
        errs.append("Starts with lowercase letter")
    return errs


def check_keys_exist_in_reference(reference_strings, checked_strings):
    errs = []
    for key in checked_strings.keys():
        if key not in reference_strings:
            errs.append(f"Invalid key: {key}")
    return errs


def lint_strings(strings, rules):
    for k, v in strings.items():
        errs = []
        errs.extend(
            check_prefixes(
                k,
                v,
                rules.get("s_max_words", 4),
                rules.get("s_max_len", 32),
            )
        )
        errs.extend(check_misc(k, v))
        if errs:
            errors.append(f'Errors in {k}: "{v}"')
            errors.extend([f"  {e}" for e in errs])


if len(sys.argv) != 2:
    print("USAGE: check_strings.py <ARB_FILE>")
    sys.exit(1)


target = sys.argv[1]
with open(target, encoding='utf-8') as f:
    values = json.load(f, object_pairs_hook=check_duplicate_keys)

strings = {k: v for k, v in values.items() if not k.startswith("@")}

print(target, f"- checking {len(strings)} strings")
lint_strings(strings, strings.get("@_lint_rules", {}))
check_duplicate_values(strings)

with open(os.path.join(os.path.dirname(target), 'app_en.arb'), encoding='utf-8') as f:
    reference_values = json.load(f)
errors.extend(check_keys_exist_in_reference(reference_values, values))


if errors:
    print()
    print(target, "HAS ERRORS:")
    for e in errors:
        print(e)
    print()
    sys.exit(1)

print(target, "OK")
