#!/usr/bin/env python3

import os

# Function to load the contents of a file into a line list
def read_file_lines(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.readlines()

# Function to save a list of lines to a file
def write_lines_to_file(file_path, lines):
    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(lines)

# Function to update the ARB files
def update_arb_file(source_path, target_path, language_code):
    # Load the contents of the source file 'app_en.arb'
    source_lines = read_file_lines(source_path)

    # Load the contents of the target file 'app_**.arb'
    target_lines = read_file_lines(target_path)

    # Create a translation dictionary based on the contents of the target file
    translation_dict = {}
    in_placeholders = False
    in_readme = False
    in_lint_rules = False

    for line in target_lines:
        if line.strip() == '"placeholders": {':
            in_placeholders = True
            continue
        elif line.strip() == '"@_readme": {':
            in_readme = True
            continue
        elif line.strip() == '"@_lint_rules": {':
            in_lint_rules = True
            continue

        if in_placeholders:
            if line.strip() == '},':
                in_placeholders = False
            continue
        elif in_readme:
            if line.strip() == '},':
                in_readme = False
            continue
        elif in_lint_rules:
            if line.strip() == '},':
                in_lint_rules = False
            continue

        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip().strip('"')
            value = value.strip().strip(",").strip('"')
            if not key.startswith("@"):
                # only add non special keys
                translation_dict[key] = value

    # Update the target file based on the source file
    updated_target_lines = []

    for line in source_lines:
        if line.strip() == '"placeholders": {':
            in_placeholders = True
        elif line.strip() == '"@_readme": {':
            in_readme = True
        elif line.strip() == '"@_lint_rules": {':
            in_lint_rules = True

        if in_placeholders:
            if line.strip() == '},':
                in_placeholders = False
        elif in_readme:
            if line.strip() == '},':
                in_readme = False
        elif in_lint_rules:
            if line.strip() == '},':
                in_lint_rules = False

        if '"@@locale": "en"' in line:
            line = line.replace('"@@locale": "en"', f'"@@locale": "{language_code}"')

        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip().strip('"')
            if key in translation_dict:
                updated_line = f'    "{key}": "{translation_dict[key]}",\n'
                updated_target_lines.append(updated_line)
            elif key.startswith("@_eof"):
                # eof will be the last line, will not have trailing comma
                updated_target_lines.append(line.strip(","))
            elif in_readme or in_lint_rules or in_placeholders or key.startswith("@"):
                # replicate lines from special sections
                updated_target_lines.append(line)
            else:
                # if a key is missing, don't include it at all
                updated_target_lines.append('\n')
        else:
            updated_target_lines.append(line)

    # Save the updated target file
    write_lines_to_file(target_path, updated_target_lines)

if __name__ == "__main__":
    source_file_path = 'lib/l10n/app_en.arb'
    target_directory = 'lib/l10n'
    language_code = os.path.basename(source_file_path).split('_')[1].split('.')[0]

    for file_name in os.listdir(target_directory):
        if file_name.startswith('app_') and file_name.endswith('.arb') and file_name != os.path.basename(source_file_path):
            target_file_path = os.path.join(target_directory, file_name)
            update_arb_file(source_file_path, target_file_path, language_code)
            print(f'File updated: {file_name}')
