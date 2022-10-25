@echo off

echo Building authenticator-helper for Windows...
cd helper
poetry install
rmdir /s /q ..\build\windows\helper
poetry run pyinstaller authenticator-helper.spec --distpath ..\build\windows

echo Generating license files...
rmdir /s /q ..\build\windows\helper-license-venv
poetry build
poetry run python -m venv ..\build\windows\helper-license-venv
..\build\windows\helper-license-venv\Scripts\python -m pip install --upgrade pip wheel
..\build\windows\helper-license-venv\Scripts\python -m pip install dist\authenticator_helper-0.1.0-py3-none-any.whl pip-licenses
..\build\windows\helper-license-venv\Scripts\pip-licenses --format=json --no-license-path --with-license-file --ignore-packages authenticator-helper zxing-cpp --output-file ..\assets\licenses\helper.json

cd ..

echo All done, output in build/windows/
