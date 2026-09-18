#!/bin/bash -x

# Generate Third-party licenses
pushd android
./gradlew collectLicenses
popd

# Build flutter app. The abi splits config (universalApk) makes this single
# command emit both the per-ABI APKs and the universal app-release.apk.
flutter build apk --release --split-per-abi
