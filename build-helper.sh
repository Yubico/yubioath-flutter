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

# Create a universal binary on MacOS
if [ "$OS" = "macos" ]; then
	PYTHON=`poetry run python -c "import sys; print(sys.executable)"`
	echo "Using Python: $PYTHON"
	if [ $(lipo -archs $PYTHON | grep -c 'x86_64 arm64') -ne 0 ]; then
		echo "Fixing single-arch dependencies..."
		HELPER="../$OUTPUT/helper"
		rm -rf $HELPER
		mkdir -p $HELPER

		# Needed to build zxing-cpp properly
		export CMAKE_OSX_ARCHITECTURES="arm64;x86_64"

		# Export exact versions
		poetry export --without-hashes > $HELPER/requirements.txt
		grep cryptography $HELPER/requirements.txt > $HELPER/cryptography.txt
		grep cffi $HELPER/requirements.txt > $HELPER/cffi.txt
		grep pillow $HELPER/requirements.txt > $HELPER/pillow.txt
		grep zxing-cpp $HELPER/requirements.txt > $HELPER/zxing-cpp.txt
		# Remove non-universal packages
		poetry run pip uninstall -y cryptography cffi pillow zxing-cpp
		# Build cffi from source to get universal build
		poetry run pip install --upgrade -r $HELPER/cffi.txt --no-binary cffi
		# Build zxing-cpp from source to get universal build
		poetry run pip install --upgrade -r $HELPER/zxing-cpp.txt --no-binary zxing-cpp
		# Explicitly install pre-build universal build of cryptography
		poetry run pip download -r $HELPER/cryptography.txt --platform macosx_10_12_universal2 --only-binary :all: --no-deps --dest $HELPER
		poetry run pip install -r $HELPER/cryptography.txt --no-cache-dir --no-index --find-links $HELPER
		# Combine wheels of pillow to get universal build
		poetry run pip download -r $HELPER/pillow.txt --platform macosx_10_10_x86_64 --only-binary :all: --no-deps --dest $HELPER
		poetry run pip download -r $HELPER/pillow.txt --platform macosx_11_0_arm64 --only-binary :all: --no-deps --dest $HELPER
		poetry run pip install delocate
		poetry run delocate-fuse $HELPER/Pillow*.whl
		WHL=$(ls $HELPER/Pillow*x86_64.whl)
		UNIVERSAL_WHL=${WHL//x86_64/universal2}
		mv $WHL $UNIVERSAL_WHL
		poetry run pip install --upgrade $UNIVERSAL_WHL
	fi
fi

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

echo "Generating license files..."
cd helper
poetry build
VENV="../$OUTPUT/helper-license-venv"
rm -rf $VENV
poetry run python -m venv $VENV
$VENV/bin/pip install --upgrade pip wheel
$VENV/bin/pip install dist/authenticator_helper-0.1.0-py3-none-any.whl pip-licenses
$VENV/bin/pip-licenses --format=json --no-license-path --with-license-file --ignore-packages authenticator-helper zxing-cpp --output-file ../assets/licenses/helper.json
cd ..

echo "All done, output in $OUTPUT/"
