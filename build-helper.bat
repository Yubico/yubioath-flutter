@echo off

echo Building authenticator-helper for Windows...
cd helper
poetry install
rmdir /s /q ..\build\windows\helper
poetry run pyinstaller authenticator-helper.spec --distpath ..\build\windows
cd ..

echo All done, output in build/windows/
