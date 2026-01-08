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

import os
import subprocess
import sys


def main():
    android_dir = os.path.join(os.path.dirname(__file__), "android")
    os.chdir(android_dir)
    gradlew = "./gradlew" if sys.platform != "win32" else "gradlew.bat"
    result = subprocess.run([gradlew, "spotlessApply"], check=True)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
