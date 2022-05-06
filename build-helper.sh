#!/bin/sh

#
# This script creates a pyinstaller build of yubikey-manager from the submodule in this repository.
#

set -e

case "$(uname)" in
	Darwin*) 
		OS="macos";;
	Linux*)
		OS="linux";;
	MINGW*)
		OS="windows";;
esac

echo "Building authenticator-helper for $OS..."
OUTPUT="build/$OS"

cd helper
poetry install
rm -rf ../$OUTPUT/helper
poetry run pyinstaller authenticator-helper.spec --distpath ../$OUTPUT
cd ..

# Fixup permissions (should probably be more strict)
find $OUTPUT/helper -type f -exec chmod a-x {} +
chmod a+x $OUTPUT/helper/authenticator-helper

# Adhoc sign executable (MacOS)
if [ "$OS" = "macos" ]; then
	codesign -f --timestamp --entitlements macos/helper.entitlements --sign - $OUTPUT/helper/authenticator-helper
fi

echo "All done, output in $OUTPUT/"
