#!/bin/sh

set -e

# Run the test runner script with the provided arguments
uv --project helper/ run integration_test/runner.py "$@"
