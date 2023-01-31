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

# Build a universal2 binary on MacOS
if [ "$OS" = "macos" ]; then
	export CFLAGS="-arch x86_64 -arch arm64"
	export ARCHFLAGS="-arch x86_64 -arch arm64"
fi

cd helper
poetry install

# Replace arch specific packages with universal ones
if [ "$OS" = "macos" ]; then
	# Export exact versions
	poetry export --without-hashes > requirements.txt
	grep cryptography requirements.txt > cryptography.txt
	grep cffi requirements.txt > source-reqs.txt
	grep pyscard requirements.txt >> source-reqs.txt
	# Remove non-universal packages
	poetry run pip uninstall -y cryptography cffi pyscard
	# Build cffi from source to get universal build
	poetry run pip install --upgrade -r source-reqs.txt --no-binary :all:
	# Explicitly install pre-build universal build of cryptography
	poetry run pip download -r cryptography.txt --platform macosx_10_12_universal2 --only-binary :all: --no-deps --dest .
	poetry run pip install -r cryptography.txt --no-cache-dir --no-index --find-links .
	rm requirements.txt cryptography.txt source-reqs.txt
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
