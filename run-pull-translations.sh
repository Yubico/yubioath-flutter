#!/bin/sh
set -e

env_name="crowdin_env"
# Create venv if it does not exist
if [ ! -d "$env_name" ]; then
    echo "Creating virtual env '$env_name'"
    python3 -m venv "$env_name"
else
    echo "Using already existing environment '$env_name'"
fi

# Activate venv
source "./$env_name/bin/activate"

# Install dependencies
echo "Installing dependencies..."
pip install pyaml

# Run script
echo "Running pull-translations.py..."
python3 pull-translations.py

# Deactivate venv
deactivate

# Run arb-formatter
echo "Reformatting arb files..."
pre-commit run arb-reformatter --all-files