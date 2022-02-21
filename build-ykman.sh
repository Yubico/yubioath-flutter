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

echo "Building ykman-rpc for $OS..."
OUTPUT="build/$OS"

cd ykman-rpc
poetry install
rm -rf ../$OUTPUT/ykman-rpc
poetry run pyinstaller ykman-rpc.spec --distpath ../$OUTPUT
cd ..

# Fixup permissions (should probably be more strict)
find $OUTPUT/ykman-rpc -type f -exec chmod a-x {} +
chmod a+x $OUTPUT/ykman-rpc/ykman-rpc

# Adhoc sign executable (MacOS)
if [ "$OS" = "macos" ]; then
	codesign -f --timestamp --entitlements macos/ykman.entitlements --sign - $OUTPUT/ykman-rpc/ykman-rpc
fi

echo "All done, output in $OUTPUT/"
