@echo off

echo Building authenticator-helper for Windows...
cd helper
poetry install || goto :error
rmdir /s /q ..\build\windows\helper
poetry run pyinstaller authenticator-helper.spec --distpath ..\build\windows || goto :error

echo Generating license files...
rmdir /s /q ..\build\windows\helper-license-venv
poetry build || goto :error
poetry run python -m venv ..\build\windows\helper-license-venv || goto :error
..\build\windows\helper-license-venv\Scripts\python -m pip install --upgrade pip wheel || goto :error
..\build\windows\helper-license-venv\Scripts\python -m pip install dist\authenticator_helper-0.1.0-py3-none-any.whl pip-licenses || goto :error
..\build\windows\helper-license-venv\Scripts\pip-licenses --format=json --no-license-path --with-license-file --ignore-packages authenticator-helper zxing-cpp --output-file ..\assets\licenses\helper.json || goto :error

cd ..

echo All done, output in build/windows/
goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
