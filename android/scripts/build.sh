#!/bin/bash -x

# Generate Third-party licenses
pushd android
./gradlew collectLicenses
popd

# Build flutter app
flutter build apk --release --split-per-abi
flutter build apk --release
