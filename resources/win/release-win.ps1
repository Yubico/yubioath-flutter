$version="7.1.1-dev.0"

echo "Clean-up of old files"
rm *.msi
rm *.wixobj
rm *.wxs
rm *.wixpdb

echo "Renaming the Actions folder and moving it"
mv yubioath-desktop-* release

echo "Signing the executables"
signtool.exe sign /sha1 cb7cade8f51d0985d806bcd28e1fec57d3034187 /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/authenticator.exe
signtool.exe sign /sha1 cb7cade8f51d0985d806bcd28e1fec57d3034187 /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/helper/authenticator-helper.exe

echo "Setting env var and building installer"
$env:SRCDIR = ".\release\"
& "$env:WIX\bin\heat.exe" dir .\release -out fragment.wxs -gg -scom -srd -sfrag -dr INSTALLDIR -cg ApplicationFiles -var env.SRCDIR
& "$env:WIX\bin\candle.exe" .\fragment.wxs resources/win/yubioath-desktop.wxs -ext WixUtilExtension -arch x64
& "$env:WIX\bin\light.exe" fragment.wixobj yubioath-desktop.wixobj -ext WixUIExtension -ext WixUtilExtension -o yubico-authenticator-$version-win64.msi

echo "Signing the installer"
signtool.exe sign /sha1 cb7cade8f51d0985d806bcd28e1fec57d3034187 /d "Yubico Authenticator" /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll yubico-authenticator-$version-win64.msi

echo "All done"