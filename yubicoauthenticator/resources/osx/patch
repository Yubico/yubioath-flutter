#!/bin/sh   

#exit on error
set -e       

#define file
FILE="/usr/libexec/SmartCardServices/drivers/ifd-ccid.bundle/Contents/Info.plist"

if [ -f $FILE ];
then
	if grep -q 'Yubikey' "$FILE"
	then
		echo "already patched"
	else
		/usr/bin/patch -d/ -p0 < libccid-yubikey.diff
	fi

else
   echo "File $FILE does not exist. Did you installed the CCID TOOLS?"
fi