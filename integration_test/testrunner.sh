#!/bin/bash

#
# Copyright (C) 2022 Yubico.
#
# This file defines which tests we should run in the CI environment
# It is now being used to check for flakiness, as we haven't decided
# which tests will be run in CI.

case "$(uname)" in
	Darwin*)
		OS="macos";;
	Linux*)
		OS="linux";;
	MINGW*)
		OS="windows";;
esac

# Measure the start time
start_time=$(date +%s.%N)

# Run the keyless tests and measure the time
keyless_start_time=$(date +%s.%N)
outputKeyless=$(flutter test -d $OS integration_test/keyless_test.dart)
keyless_end_time=$(date +%s.%N)
keyless_time=$(echo "$keyless_end_time - $keyless_start_time" | bc)

# Run the management tests and measure the time
management_start_time=$(date +%s.%N)
outputManagement=$(flutter test -d $OS integration_test/management_test.dart)
management_end_time=$(date +%s.%N)
management_time=$(echo "$management_end_time - $management_start_time" | bc)

# Run the PIV tests and measure the time
piv_start_time=$(date +%s.%N)
outputPiv=$(flutter test -d $OS integration_test/piv_test.dart)
piv_end_time=$(date +%s.%N)
piv_time=$(echo "$piv_end_time - $piv_start_time" | bc)

# Run the OATH tests and measure the time
oath_start_time=$(date +%s.%N)
outputOath=$(flutter test -d $OS integration_test/oath_test.dart)
oath_end_time=$(date +%s.%N)
oath_time=$(echo "$oath_end_time - $oath_start_time" | bc)

# Run the webauthn tests and measure the time
webauthn_start_time=$(date +%s.%N)
outputWebauthn=$(flutter test -d $OS integration_test/webauthn_test.dart)
webauthn_end_time=$(date +%s.%N)
webauthn_time=$(echo "$webauthn_end_time - $webauthn_start_time" | bc)

# Measure the end time
end_time=$(date +%s.%N)

# Calculate the total time
total_time=$(echo "$end_time - $start_time" | bc)

# Output the measured times
if [[ $outputPiv == *"All tests passed"* ]]; then
    echo "All PIV tests passed: $piv_time seconds"
fi
if [[ $outputOath == *"All tests passed"* ]]; then
    echo "All OATH tests passed: $oath_time seconds"
fi
if [[ $outputWebauthn == *"All tests passed"* ]]; then
    echo "All Webauthn tests passed: $webauthn_time seconds"
fi
if [[ $outputKeyless == *"All tests passed"* ]]; then
    echo "All Keyless tests passed: $keyless_time seconds"
fi
if [[ $outputManagement == *"All tests passed"* ]]; then
    echo "All Management tests passed: $management_time seconds"
fi
#echo "PIV test time: $piv_time seconds"
#echo "OATH test time: $oath_time seconds"
echo "Total time: $total_time seconds"