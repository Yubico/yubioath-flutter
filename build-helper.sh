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
uv sync --locked

# Create a universal binary on MacOS
if [ "$OS" = "macos" ]; then
	PYTHON=`uv run python -c "import sys; print(sys.executable)"`
	echo "Using Python: $PYTHON"
	if [ $(lipo -archs $PYTHON | grep -c 'x86_64 arm64') -ne 0 ]; then
		echo "Fixing single-arch dependencies..."
		export MACOSX_DEPLOYMENT_TARGET="10.15"
		export CFLAGS="-arch x86_64 -arch arm64"
		export ARCHFLAGS="-arch x86_64 -arch arm64"
		HELPER="../$OUTPUT/helper"
		rm -rf $HELPER
		mkdir -p $HELPER

		# Export exact versions
          	uv pip freeze  > $HELPER/requirements.txt
		grep cryptography $HELPER/requirements.txt > $HELPER/cryptography.txt
		grep cffi $HELPER/requirements.txt > $HELPER/cffi.txt
		grep pillow $HELPER/requirements.txt > $HELPER/pillow.txt
		# Remove non-universal packages
		uv pip uninstall cryptography cffi pillow
		# Build cffi from source to get universal build
		uv pip install --upgrade -r $HELPER/cffi.txt --no-binary cffi
		# Explicitly install pre-build universal build of cryptography
		pip download -r $HELPER/cryptography.txt --platform macosx_10_12_universal2 --only-binary :all: --no-deps --dest $HELPER
		uv pip install -r $HELPER/cryptography.txt --no-cache-dir --no-index --find-links $HELPER
		# Combine wheels of pillow to get universal build
		pip download -r $HELPER/pillow.txt --platform macosx_10_13_x86_64 --only-binary :all: --no-deps --dest $HELPER
		pip download -r $HELPER/pillow.txt --platform macosx_11_0_arm64 --only-binary :all: --no-deps --dest $HELPER
		uv run delocate-merge $HELPER/pillow*.whl
		UNIVERSAL_WHL=$(ls $HELPER/pillow*universal2.whl)
		uv pip install --upgrade $UNIVERSAL_WHL
	fi
fi

rm -rf ../$OUTPUT/helper
uv run pyinstaller authenticator-helper.spec --distpath ../$OUTPUT
cd ..

# Fixup permissions (should probably be more strict)
find $OUTPUT/helper -type f -exec chmod a-x {} +
chmod a+x $OUTPUT/helper/authenticator-helper

# Adhoc sign executable (MacOS)
if [ "$OS" = "macos" ]; then
	codesign -f --timestamp --entitlements macos/helper.entitlements --sign - $OUTPUT/helper/authenticator-helper
fi

echo "Generating license files..."
cd helper
uv build
VENV="../$OUTPUT/helper-license-venv"
rm -rf $VENV
uv run python -m venv $VENV
$VENV/bin/pip install --upgrade pip wheel
$VENV/bin/pip install dist/authenticator_helper-0.1.0-py3-none-any.whl pip-licenses
$VENV/bin/pip-licenses --format=json --no-license-path --with-license-file --ignore-packages authenticator-helper zxing-cpp --output-file ../assets/licenses/helper.json
cd ..

echo "All done, output in $OUTPUT/"
