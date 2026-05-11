#!/bin/sh

#
# This script builds the authenticator-helper Rust binary.
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

if [ "$OS" = "macos" ]; then
	# Build universal binary for macOS
	cargo build --release --target aarch64-apple-darwin
	cargo build --release --target x86_64-apple-darwin

	rm -rf ../$OUTPUT/helper
	mkdir -p ../$OUTPUT/helper

	lipo -create \
		target/aarch64-apple-darwin/release/authenticator-helper \
		target/x86_64-apple-darwin/release/authenticator-helper \
		-output ../$OUTPUT/helper/authenticator-helper

	# Adhoc sign executable
	codesign -f --timestamp --entitlements ../macos/helper.entitlements --sign - ../$OUTPUT/helper/authenticator-helper
else
	cargo build --release

	rm -rf ../$OUTPUT/helper
	mkdir -p ../$OUTPUT/helper

	if [ "$OS" = "windows" ]; then
		cp target/release/authenticator-helper.exe ../$OUTPUT/helper/
	else
		cp target/release/authenticator-helper ../$OUTPUT/helper/
	fi
fi

echo "Generating license files..."
cargo about generate about.hbs --config about.toml -o ../assets/licenses/helper.txt

cd ..

echo "All done, output in $OUTPUT/"
