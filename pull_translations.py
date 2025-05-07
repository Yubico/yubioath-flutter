#!/usr/bin/env python3

#  Copyright (C) 2025 Yubico.
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


import subprocess
import sys
import os
import glob
import json
from pathlib import Path
import yaml


def get_languages(threshold):
    languages = {}
    status = subprocess.run(
        ["crowdin", "status", "--plain"], capture_output=True, text=True
    ).stdout
    kind = None
    for line in status.strip().splitlines():
        if "Translated" in line:
            kind = "translated"
            continue
        if "Proofread" in line:
            kind = "proofread"
            continue

        lang, val = line.split()
        languages.setdefault(lang, {})[kind] = int(val)
    return {
        lang: val for lang, val in languages.items() if val["translated"] > threshold
    }


def get_arb_files():
    arb_files = glob.glob("lib/l10n/*.arb")
    return [file_path for file_path in arb_files]


def delete_arb_files():
    for file_path in get_arb_files():
        file_name = Path(file_path).stem
        if file_name != "app_en":
            os.remove(file_path)


def post_process_arb_files(languages):
    language_mappings = get_language_mappings()
    for file_path in get_arb_files():
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            locale = data.get("@@locale")
            if locale in languages.keys():
                # Ensure locale is correct
                data["@@locale"] = language_mappings[locale]
                with open(file_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2)


def create_status_file(languages):
    l10n_assets_dir = "assets/l10n"
    l10n_status_file_path = os.path.join(l10n_assets_dir, "status.json")
    language_mappings = get_language_mappings()

    # create directory if not exist
    os.makedirs(l10n_assets_dir, exist_ok=True)

    # create status file
    with open(l10n_status_file_path, "w", encoding="utf-8") as f:
        l10n_status = {"en": {"translated": 100, "proofread": 100}}
        new_status = {language_mappings[lang]: val for lang, val in languages.items()}
        l10n_status.update(**new_status)
        json.dump(l10n_status, f, indent=2)
        print(f"Created status file '{l10n_status_file_path}'")


def crowdin_pull(languages):
    lang_args = [f"--language={lang}" for lang in languages.keys()]
    subprocess.run(["crowdin", "pull", *lang_args], check=True)


def get_language_mappings():
    with open("crowdin.yaml", "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
        file_config = config["files"][0]
        return file_config["languages_mapping"]["locale"]


def missing_language_mappings(languages):
    language_mappings = get_language_mappings()
    return set(languages.keys()) - set(language_mappings.keys())


if __name__ == "__main__":
    threshold = 70
    argv = sys.argv
    if len(argv) > 1:
        threshold = int(argv[1])
    print(f"Using threshold {threshold}%")
    print("Fetching language status...")
    languages = get_languages(threshold)
    if not languages:
        print("No languages above threshold were found")
    else:
        print(
            f"Found {len(languages)} languages matching "
            f"threshold: {', '.join(languages.keys())}"
        )
    # Check if we are missing mappings
    missing_mappings = missing_language_mappings(languages)
    if missing_mappings:
        print(
            "ERROR: No language_mappings were found "
            f"for: {', '.join(list(missing_mappings))}. "
            "Create the mappings in 'crowdin.yaml' to continue."
        )
        exit(1)
    print("Deleting existing arb files...")
    delete_arb_files()
    print("Fetching translations for languages from crowdin...")
    crowdin_pull(languages)
    post_process_arb_files(languages)
    create_status_file(languages)
