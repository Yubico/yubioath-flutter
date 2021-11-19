@echo off

REM Make sure the submodule is cloned, but if it already is, don't reset it.
( dir /b /a "yubikey-manager" | findstr . ) > nul || (
	git submodule init
	git submodule update
)

echo Building ykman CLI for Windows...
cd yubikey-manager
poetry install
rmdir /s /q ..\build\windows\ykman
poetry run pyinstaller ykman.spec --distpath ..\build\windows
cd ..

echo All done, output in build/windows/
