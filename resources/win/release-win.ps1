$ErrorActionPreference = "Stop"
$version="7.5.0-dev.0"

echo "Clean-up of old files"
rm *.msi
rm *.wixobj
rm *.wxs
rm *.wixpdb

echo "Renaming the Actions folder and moving it"
mv yubioath-desktop-* release

echo "Signing the executables"
signtool.exe sign /sha1 a1614cd84976030d49209b56162d9efa69b73698 /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/authenticator.exe
signtool.exe sign /sha1 a1614cd84976030d49209b56162d9efa69b73698 /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll release/helper/authenticator-helper.exe
$serviceSource = (Resolve-Path .\ykman-svc.exe).Path
signtool.exe sign /sha1 a1614cd84976030d49209b56162d9efa69b73698 /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll $serviceSource

echo "Setting env var and building installer"
$env:SRCDIR = ".\release\"
& .\service-module\make_service_msm.ps1 -ServiceSource $serviceSource -Architecture x64 -OutputPath .\ykman-service.msm
$serviceModule = (Resolve-Path .\ykman-service.msm).Path
& "$env:WIX\bin\heat.exe" dir .\release -out fragment.wxs -gg -scom -srd -sfrag -dr INSTALLDIR -cg ApplicationFiles -var env.SRCDIR
if ($LASTEXITCODE -ne 0) { throw 'WiX heat failed' }
& "$env:WIX\bin\candle.exe" .\fragment.wxs resources/win/yubioath-desktop.wxs "-dServiceModule=$serviceModule" -ext WixUtilExtension -arch x64
if ($LASTEXITCODE -ne 0) { throw 'WiX candle failed' }
& "$env:WIX\bin\light.exe" fragment.wixobj yubioath-desktop.wixobj -ext WixUIExtension -ext WixUtilExtension -o yubico-authenticator-$version-win64.msi
if ($LASTEXITCODE -ne 0) { throw 'WiX light failed' }

echo "Signing the installer"
signtool.exe sign /sha1 a1614cd84976030d49209b56162d9efa69b73698 /d "Yubico Authenticator" /fd SHA256 /t http://timestamp.digicert.com/scripts/timstamp.dll yubico-authenticator-$version-win64.msi

echo "All done"
