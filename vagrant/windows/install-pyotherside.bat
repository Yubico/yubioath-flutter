SET QT_VERSION=5.9.3

REM Needed for jom to work.
CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC"\vcvarsall.bat x86
REM Add python and Qt to PATH
SET "PATH=%PATH%;C:\Python36\Scripts;C:\Qt\%QT_VERSION%\msvc2015\bin;C:\Qt\Tools\QtCreator\bin;"

REM Install pyotherside
cd vendor\pyotherside
powershell -Command "(Get-Content .\src\qmldir).replace('pyothersideplugin', 'pyothersideplugin1') | Set-Content .\src\qmldir"
powershell -Command "Clear-Content python.pri
powershell -Command "Add-Content python.pri \"PYTHON_CONFIG = python3-config`nQMAKE_LIBS += -LC:\Python36\libs -lpython36`nQMAKE_CXXFLAGS += -IC:\Python36\include`n\""
qmake
jom
jom install
cd ..\..
