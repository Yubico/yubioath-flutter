#!/bin/sh

# Runs mypy from poetry in the helper directory.
set -e

cd helper

if [ "$(poetry env list)" = "" ]; then
	echo "Initializing poetry env..."
	poetry install
fi

poetry run mypy
