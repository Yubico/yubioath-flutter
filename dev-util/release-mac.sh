#!/bin/bash

# Exit on error
set -e

PROJECT_NAME='yubioath-desktop'
APP_NAME='Yubico Authenticator'
APP_DIR_IN_TAR="."

version=$(python3 compute-version.py "${PROJECT_NAME}"-)

rm -rf "deploy/unpacked"

mkdir -p deploy/unpacked
cd deploy/unpacked

tar xf "../${PROJECT_NAME}-${version}.app.tar"
cd "${APP_DIR_IN_TAR}"
mv "${PROJECT_NAME}.app" "${APP_NAME}.app"

codesign --deep --verify --verbose --sign 'Developer ID Application' "${APP_NAME}.app"
productbuild --sign 'Developer ID Installer' --component "${APP_NAME}.app" /Applications/ "${PROJECT_NAME}-${version}-mac.pkg"
gpg --detach-sign "${PROJECT_NAME}-${version}-mac.pkg"
