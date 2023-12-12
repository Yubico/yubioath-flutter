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

# directory containing the integration tests
int_directory="integration_test/"

# Measure the start time
start_time=$(date +%s.%N)

# Run the keyless tests and measure the time
keyless_start_time=$(date +%s.%N)
outputKeyless=$(flutter test -d $OS "$int_directory"keyless_test.dart)
keyless_end_time=$(date +%s.%N)
keyless_time=$(echo "$keyless_end_time - $keyless_start_time" | bc)

# Run the management tests and measure the time
management_start_time=$(date +%s.%N)
outputManagement=$(flutter test -d $OS "$int_directory"management_test.dart)
management_end_time=$(date +%s.%N)
management_time=$(echo "$management_end_time - $management_start_time" | bc)

# Run the PIV tests and measure the time
piv_start_time=$(date +%s.%N)
outputPiv=$(flutter test -d $OS "$int_directory"piv_test.dart)
piv_end_time=$(date +%s.%N)
piv_time=$(echo "$piv_end_time - $piv_start_time" | bc)

# Run the OATH tests and measure the time
oath_start_time=$(date +%s.%N)
outputOath=$(flutter test -d $OS "$int_directory"oath_test.dart)
oath_end_time=$(date +%s.%N)
oath_time=$(echo "$oath_end_time - $oath_start_time" | bc)

# Run the webauthn tests and measure the time
webauthn_start_time=$(date +%s.%N)
outputWebauthn=$(flutter test -d $OS "$int_directory"webauthn_test.dart)
webauthn_end_time=$(date +%s.%N)
webauthn_time=$(echo "$webauthn_end_time - $webauthn_start_time" | bc)

# Measure the end time
end_time=$(date +%s.%N)

# Calculate the total time
total_time=$(echo "$end_time - $start_time" | bc)

# Output the measured times
if [[ $outputPiv == *"All tests passed"* ]]; then
    echo "All PIV tests passed: $piv_time seconds"
else
    echo "PIV tests failed"
    echo $outputPiv
fi

if [[ $outputOath == *"All tests passed"* ]]; then
    echo "All OATH tests passed: $oath_time seconds"
else
    echo "OATH tests failed"
    echo $outputOath
fi

if [[ $outputWebauthn == *"All tests passed"* ]]; then
    echo "All Webauthn tests passed: $webauthn_time seconds"
else
    echo "Webauthn tests failed"
    echo $outputWebauthn
fi
if [[ $outputKeyless == *"All tests passed"* ]]; then
    echo "All Keyless tests passed: $keyless_time seconds"
else
    echo "Keyless tests failed"
    echo $outputKeyless
fi

if [[ $outputManagement == *"All tests passed"* ]]; then
    echo "All Management tests passed: $management_time seconds"
else
    echo "Managemet tests failed"
    echo $outputManagement
fi

echo "Total time: $total_time seconds"