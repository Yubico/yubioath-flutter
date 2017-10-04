SET "VERSION=0.0.0-test"

REM Clean build
rm -rf Z:\release

REM Download Appveyor build
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://yubico-builds.s3-eu-west-1.amazonaws.com/yubioath-desktop/yubioath-desktop-master-win.zip', 'C:\Users\vagrant\Downloads\yubioath-desktop-master-win.zip')"
7z x -oZ:\release C:\Users\vagrant\Downloads\yubioath-desktop-master-win.zip

signtool sign /fd SHA256 /t http://timestamp.verisign.com/scripts/timstamp.dll release\yubioath-desktop.exe
"C:\Program Files (x86)\NSIS\makensis" -D"VERSION=%VERSION%" resources\win\win-installer.nsi
signtool sign /fd SHA256 /t http://timestamp.verisign.com/scripts/timstamp.dll "yubioath-desktop-%VERSION%-win.exe"
gpg --detach-sign "yubioath-desktop-%VERSION%-win.exe"
