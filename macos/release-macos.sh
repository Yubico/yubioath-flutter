#!/bin/sh

if [ -z "$1" ]
then
	echo "No username given"
	exit
fi

if [ -z "$2" ]
then
	echo "No password given"
	exit
fi

if ! command -v create-dmg &> /dev/null
then
	echo "create-dmg could not be found"
	exit
fi


echo "# Extract .app from .tar.gz"
tar -xzvf yubioath-desktop*.tar.gz

echo "# Sign the main binaries, with the entitlements"
codesign -f --timestamp --options runtime --entitlements helper.entitlements --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper/authenticator-helper
codesign -f --timestamp --options runtime --entitlements helper.entitlements --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper-arm64/authenticator-helper

echo "# Sign the dylib and so files, without entitlements"
cd Yubico\ Authenticator.app/
codesign -f --timestamp --options runtime --sign 'Application' $(find Contents/Resources/helper/ -name "*.dylib" -o -name "*.so")
codesign -f --timestamp --options runtime --sign 'Application' $(find Contents/Resources/helper-arm64/ -name "*.dylib" -o -name "*.so")
cd ..

echo "# Sign the Python binary (if it exists), without entitlements"
codesign -f --timestamp --options runtime --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper-arm64/Python
codesign -f --timestamp --options runtime --sign 'Application' Yubico\ Authenticator.app/Contents/Resources/helper/Python

echo "# Sign the GUI"
codesign -f --timestamp --options runtime --sign 'Application' --entitlements Release.entitlements --deep "Yubico Authenticator.app"

echo "# Compress the .app to .zip and notarize"
ditto -c -k --sequesterRsrc --keepParent "Yubico Authenticator.app" "Yubico Authenticator.zip" 
RES=$(xcrun altool -t osx -f "Yubico Authenticator.zip" --primary-bundle-id com.yubico.authenticator --notarize-app -u $1 -p $2)
echo ${RES}
ERRORS=${RES:0:9}
if [ "$ERRORS" != "No errors" ]; then
	echo "Error uploading for notarization"
	exit
fi
UUID=${RES#*=}
STATUS=$(xcrun altool --notarization-info $UUID -u $1 -p $2)

while true
do
	if [[ "$STATUS" == *"in progress"* ]]; then
		echo "Notarization still in progress. Sleep 30s."
		sleep 30
		echo "Retrieving status again."
		STATUS=$(xcrun altool --notarization-info $UUID -u $1 -p $2)
	else
		echo "Status changed."
		break
	fi
done

echo "${STATUS}"

if [[ "$STATUS" == *"success"* ]]; then
	echo "Notarization successfull. Staple the .app"
	xcrun stapler staple -v "Yubico Authenticator.app"

	echo "# Create dmg"
	rm yubioath-desktop.dmg # Remove old .dmg
	mkdir source_folder
	mv "Yubico Authenticator.app" source_folder
	sh create-dmg.sh
	echo "# .dmg created. Everything should be ready for release!"
fi

echo "# End of script"
