#!/bin/sh

if ! command -v create-dmg &> /dev/null
then
	echo "create-dmg could not be found"
	exit
fi

echo "# Extract .app from .tar.gz"
tar -xzf yubioath-desktop*.tar.gz

if [ -n "$1" ] && [ -n "$2" ] # Standalone
then
	echo "#################"
	echo "# Two parameters have been given, this will be a standalone"
	echo "#################"
	echo
	echo "# Sign the main binaries, with the entitlements"
	codesign -f --timestamp --options runtime --entitlements helper.entitlements --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper/authenticator-helper
else
	echo "#################"
	echo "# No parameters given, this will be app store"
	echo "#################"
	echo
	echo "# Sign the main binaries, with sandbox enabled, without hardened runtime"
	codesign -f --timestamp --entitlements helper-sandbox.entitlements --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper/authenticator-helper
fi

echo "# Sign the dylib and so files, without entitlements"
cd Yubico\ Authenticator.app/
codesign -f --timestamp --options runtime --sign 'Application' $(find Contents/Resources/helper/_internal/ -name "*.dylib" -o -name "*.so")
cd ..

echo "# Sign the Python binary (if it exists), without entitlements"
codesign -f --timestamp --options runtime --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper/_internal/Python

echo "# Sign the GUI"
codesign -f --timestamp --options runtime --sign 'Application' --entitlements Release.entitlements --deep "Yubico Authenticator.app"

if [ -n "$1" ] && [ -n "$2" ] # Standalone
then
	echo "# Compress the .app to .zip and notarize"
	ditto -c -k --sequesterRsrc --keepParent "Yubico Authenticator.app" "Yubico Authenticator.zip" 
	STATUS=$(xcrun notarytool submit "Yubico Authenticator.zip" --apple-id $1 --team-id LQA3CS5MM7 --password $2 --wait)
	echo ${STATUS}

	if [[ "$STATUS" == *"Accepted"* ]]; then
		echo "# Notarization successfull. Staple the .app"
		xcrun stapler staple -v "Yubico Authenticator.app"

		echo "# Create dmg"
		rm yubioath-desktop.dmg # Remove old .dmg
		mkdir source_folder
		mv "Yubico Authenticator.app" source_folder
		sh create-dmg.sh
		echo "# .dmg created."
	else
		echo "Error uploading for notarization"
		exit
	fi

	echo "# Sign the .dmg"
	codesign -f --timestamp --options runtime --sign 'Application' yubioath-desktop.dmg
	echo "# Notarize the .dmg"
	STATUS=$(xcrun notarytool submit "yubioath-desktop.dmg" --apple-id $1 --team-id LQA3CS5MM7 --password $2 --wait)
	echo ${STATUS}
	echo "# Staple the .dmg"
	xcrun stapler staple -v yubioath-desktop.dmg

	echo "# Everything should be ready for release!"
else # App store
	echo "# Build the package for AppStore submission"
	productbuild --sign 'Installer' --component "Yubico Authenticator.app" /Applications/ output-appstore.pkg
fi

echo "# End of script"
