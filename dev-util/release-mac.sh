#!/bin/bash

# Exit on error
set -e

PROJECT_NAME='yubioath-desktop'
APP_NAME='Yubico Authenticator'
APP_DIR_IN_TAR="."

version=$(python3 compute-version.py "${PROJECT_NAME}"-)

echo "Building release: ${version}"

rm -rf "deploy/unpacked"

mkdir -p deploy/unpacked
cd deploy/unpacked

tar xf "../${PROJECT_NAME}-${version}.app.tar"
cd "${APP_DIR_IN_TAR}"
mv "${PROJECT_NAME}.app" "${APP_NAME}.app"

echo "Running codesign..."
codesign --deep --verify --verbose --sign 'Developer ID Application' "${APP_NAME}.app"

echo "Running productbuild..."
productbuild --sign 'Developer ID Installer' --component "${APP_NAME}.app" /Applications/ "${PROJECT_NAME}-${version}-mac.pkg"

echo "Checking package signature..."
if pkgutil --check-signature "${PROJECT_NAME}-${version}-mac.pkg"; then
  echo "Package is signed - generating PGP signature"
  gpg --detach-sign "${PROJECT_NAME}-${version}-mac.pkg"
else
  echo "Package is NOT signed!"
fi
