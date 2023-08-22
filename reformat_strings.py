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
import sys


class ArbKeySort(str):
    def __lt__(self, other):
        a = self.lstrip("@")
        b = other.lstrip("@")

        if a == "locale":
            return True

        if b == "locale":
            return False

        if a == "_readme":
            return True

        if b == "_readme":
            return False

        if a == "_lint_rules":
            return True

        if b == "_lint_rules":
            return False

        if a == "app_name":
            return True

        if b == "app_name":
            return False

        return str.__lt__(a, b)


if len(sys.argv) != 2:
    print("USAGE: reformat_strings.py <ARB_FILE>")
    sys.exit(1)


def remove_empty_properties(d):
    result = {}
    for a, b in d.items():
        if not a.startswith("@"):
            result[a] = b
        elif b:
            if isinstance(b, dict):
                result[a] = remove_empty_properties(b)
            elif isinstance(b, list):
                result[a] = list(filter(None, [remove_empty_properties(i) for i in b]))
            else:
                result[a] = b
    return result


target = sys.argv[1]
with open(target, encoding='utf-8') as f:
    values = json.load(f)

with open(target, 'w', encoding='utf-8') as f:
    json.dump({ArbKeySort(key): value for key, value in remove_empty_properties(values).items()},
              f, ensure_ascii=False, indent=4, sort_keys=True)
