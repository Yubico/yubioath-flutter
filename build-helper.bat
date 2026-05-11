@echo off

echo Building authenticator-helper for Windows...
cd helper
cargo build --release || goto :error

rmdir /s /q ..\build\windows\helper 2>nul
mkdir ..\build\windows\helper
copy target\release\authenticator-helper.exe ..\build\windows\helper\ || goto :error

echo Generating license files...
cargo about generate about.hbs --config about.toml -o ..\assets\licenses\helper.txt || goto :error

cd ..

echo All done, output in build/windows/
goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
