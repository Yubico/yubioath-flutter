@echo off

echo Building ykman-rpc for Windows...
cd ykman-rpc
poetry install
rmdir /s /q ..\build\windows\ykman-rpc
poetry run pyinstaller ykman-rpc.spec --distpath ..\build\windows
cd ..

echo All done, output in build/windows/
