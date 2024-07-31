#!/bin/bash

#
# Copyright (C) 2023 Yubico.
#
# This file defines which tests we should run in the CI environment
# It is now being used to check for flakiness, as we haven't decided
# which tests will be run in CI.

if (( $# < 1 )); then
    echo "Usage $(basename $0) DEVICE_ID [TAGS]"
    exit 1
fi

DEVICE="${1}"

if (( $# < 2 )); then
  TAGS="android" # default
else
  TAGS="(${2}) && android"
fi

echo "Running tests matching tag expression: $TAGS"

ANDROID_TESTS=('integration_test/oath_test.dart' 'integration_test/keyless_test.dart')

DRIVER="integration_test/utils/android/test_driver.dart"

flutter test \
  --tags "${TAGS}" \
  --device-id "${DEVICE}" \
  --no-pub \
  --no-track-widget-creation \
  --reporter compact \
  --file-reporter "github:build/integration_test_run_$(date +'%Y%m%d_%H:%M:%S')" \
  "${ANDROID_TESTS[@]}"
