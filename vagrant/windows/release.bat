SET VERSION="%1"

ECHO "Building release of version: %VERSION%"

SET RELEASE_DIR=".\release"

SET "PATH=%PATH%;C:\Program Files (x86)\NSIS"

REM Download Appveyor build
REM powershell -Command "(New-Object Net.WebClient).DownloadFile('https://yubico-builds.s3-eu-west-1.amazonaws.com/yubioath-desktop/yubioath-desktop-yubioath-desktop-%VERSION%-win.zip', 'C:\Users\vagrant\Downloads\yubioath-desktop-%VERSION%-win.zip')"
REM 7z x -o"%RELEASE_DIR%" C:\Users\vagrant\Downloads\yubioath-desktop-%VERSION%-win.zip

signtool sign /fd SHA256 /t http://timestamp.verisign.com/scripts/timstamp.dll "%RELEASE_DIR%"\yubioath-desktop.exe
makensis -D"VERSION=%VERSION%" resources\win\win-installer.nsi
signtool sign /fd SHA256 /t http://timestamp.verisign.com/scripts/timstamp.dll "yubioath-desktop-%VERSION%-win.exe"
gpg --detach-sign "yubioath-desktop-%VERSION%-win.exe"
