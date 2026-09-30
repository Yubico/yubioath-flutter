#!/bin/sh

set -e

# Run the test runner script with the provided arguments
uv run --script integration_test/runner.py "$@"
