#!/bin/sh

#
# This script creates a pyinstaller build of yubikey-manager from the submodule in this repository.
#

set -e

# Make sure the submodule is cloned, but if it already is, don't reset it.
if ! [ "$(ls yubikey-manager)" ]; then
	git submodule init
	git submodule update
fi

case "$(uname)" in
	Darwin*) 
		OS="macos";;
	Linux*)
		OS="linux";;
	MINGW*)
		OS="windows";;
esac

echo "Building ykman CLI for $OS..."
OUTPUT="build/$OS"

cd yubikey-manager
poetry install
rm -rf ../$OUTPUT/ykman
poetry run pyinstaller ykman.spec --distpath ../$OUTPUT
cd ..

# Fixup permissions (should probably be more strict)
find $OUTPUT/ykman -type f -exec chmod a-x {} +
chmod a+x $OUTPUT/ykman/ykman

# Adhoc sign executable (MacOS)
if [ "$OS" = "macos" ]; then
	codesign -f --timestamp --entitlements macos/ykman.entitlements --sign - $OUTPUT/ykman/ykman
fi

echo "All done, output in $OUTPUT/"
