$version="6.3.0-dev.0"

echo "Clean-up of old files"
rm *.msi
rm *.wixobj
rm *.wxs
rm *.wixpdb

echo "Renaming the Actions folder and moving it"
mv yubioath-desktop-* release

echo "Signing the executables"
signtool.exe sign /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/authenticator.exe
signtool.exe sign /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/helper/authenticator-helper.exe

echo "Setting env var and building installer"
$env:SRCDIR = ".\release\"
heat dir .\release -out fragment.wxs -gg -scom -srd -sfrag -dr INSTALLDIR -cg ApplicationFiles -var env.SRCDIR
candle .\fragment.wxs resources/win/yubioath-desktop.wxs -ext WixUtilExtension -arch x64
light fragment.wixobj yubioath-desktop.wixobj -ext WixUIExtension -ext WixUtilExtension -o yubioath-desktop-$version-win64.msi

echo "Signing the installer"
signtool.exe sign /d "Yubico Authenticator" /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll yubioath-desktop-$version-win64.msi

echo "All done"
