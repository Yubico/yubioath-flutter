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

"""Rebuild Android String resources from ARB files."""

import json
import os
import xml.etree.ElementTree as ET
from os import path as p


escape_chars = str.maketrans(
    {
        "@": r"\@",
        "?": r"\?",
        "\n": r"\n",
        "\t": r"\t",
        "'": r"\'",
        '"': r"\"",
    }
)


def read_arb_file(file_path):
    """Load translations from flutter ARB file."""
    with open(file_path, "r", encoding="utf-8") as file:
        return json.load(file)


def get_lang_file_dir(lang):
    """Return path of Android resource directory for lang."""
    return (
        f"android/app/src/main/res/values-{lang}"
        if lang != "en"
        else "android/app/src/main/res/values"
    )


def get_lang_file(lang):
    """Return path of Android string resource file for lang."""
    return p.join(get_lang_file_dir(lang), "strings.xml")


def process_android_res(lang, arb, keys_to_translate):
    """Generate or update Android string resource for lang.

    Parameters
    ----------
    lang : str
         language code
    arb : dict
         content of flutter ARB file
    keys_to_translate : list
         string resources which will be generated or updated
    """
    res_dir = get_lang_file_dir(lang)
    if not p.exists(res_dir):
        os.makedirs(res_dir)

    res_path = get_lang_file(lang)

    res = (
        ET.parse(res_path).getroot() if p.exists(res_path) else ET.Element("resources")
    )
    for key in keys_to_translate:
        # only add the string if translation exists in arb
        if key in arb.keys() and arb[key] is not None:
            existing = res.find(f"./string[@name='{key}']")
            escaped_val = arb[key].translate(escape_chars)
            if existing is not None:
                existing.text = escaped_val
            else:
                ET.SubElement(res, "string", name=f"{key}").text = escaped_val
    tree = ET.ElementTree(res)
    ET.indent(tree, "    ")
    tree.write(res_path, encoding="utf-8", xml_declaration=True)
    return True


def get_english_strings():
    """Extract translatable strings from English Android string resource."""
    strings_en = "android/app/src/main/res/values/strings.xml"
    resources_en = ET.parse(strings_en).getroot()

    return [
        key.attrib.get("name")
        for key in resources_en
        if key.attrib.get("translatable") in [None, True]
    ]


if __name__ == "__main__":
    arb_files = "lib/l10n"
    english_strings = get_english_strings()

    for arb_file in os.listdir(arb_files):
        if arb_file.startswith("app_") and arb_file.endswith(".arb"):
            lang = arb_file.split("_", 1)[1].split(".")[0]
            arb_path = p.join(arb_files, arb_file)
            arb = read_arb_file(arb_path)
            if process_android_res(lang, arb, english_strings):
                print(f"Processed: {get_lang_file(lang)}")
