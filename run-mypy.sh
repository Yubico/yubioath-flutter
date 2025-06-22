#!/bin/sh

# Runs mypy from uv in the helper directory.
set -e

cd helper

uv run mypy
