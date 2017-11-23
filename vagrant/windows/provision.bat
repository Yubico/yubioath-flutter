net use Z: \\VBOXSVR\vagrant

REM Install Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"


choco install -y 7zip
REM choco install -y git
choco install -y gpg4win
choco install -y nsis
choco install -y python3 --x86
choco install -y swig
choco install -y wget

REM Install NSIS and nsProcess plugin
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://forums.winamp.com/attachment.php?attachmentid=48936&d=1309248568', 'C:\Users\vagrant\Downloads\nsProcess_1_6.7z')"
7z e -oC:\"Program Files (x86)"\NSIS\Include C:\Users\vagrant\Downloads\nsProcess_1_6.7z Include\nsProcess.nsh
7z e -oC:\"Program Files (x86)"\NSIS\Plugins\x86-ansi C:\Users\vagrant\Downloads\nsProcess_1_6.7z Plugin\nsProcess.dll


REM Download Qt installer for manual usage later
wget "http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe" -O "C:\Users\vagrant\Downloads\qt-unified-windows-x86-online.exe"
