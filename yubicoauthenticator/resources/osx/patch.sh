#!/bin/bash          
echo Apple does not support smart cards. Please contact Apple and ask for smartcard support. 
echo Meanwhile Yubico will fix this for you...
wait 3 
echo Applying patch...
#patch -p0 libccid-yubikey.diff
echo ...done!