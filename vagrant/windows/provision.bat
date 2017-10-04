net use Z: \\VBOXSVR\vagrant

REM Install Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"


choco install python3 -y
choco install nsis -y
choco install gpg4win -y

choco install 7zip -y

REM Install NSIS and nsProcess plugin
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://forums.winamp.com/attachment.php?attachmentid=48936&d=1309248568', 'C:\Users\vagrant\Downloads\nsProcess_1_6.7z')"
7z e -oC:\"Program Files (x86)"\NSIS\Include C:\Users\vagrant\Downloads\nsProcess_1_6.7z Include\nsProcess.nsh
7z e -oC:\"Program Files (x86)"\NSIS\Plugins\x86-ansi C:\Users\vagrant\Downloads\nsProcess_1_6.7z Plugin\nsProcess.dll


ECHO "NOTE: MANUAL STEPS NEEDED!"
ECHO "Go to Programs and Features -> Visual Studio 2015 -> Change -> Modify, select Programming Languages -> C++ and Windows and Web Development -> ClickOnce Publishing Tools and run the installer (this may take a long time)"
