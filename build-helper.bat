@echo off

set BUILD_MODE=release
set CARGO_FLAGS=--release

if /I "%~1"=="--debug" (
	set BUILD_MODE=debug
	set CARGO_FLAGS=
)

echo Building authenticator-helper for Windows (%BUILD_MODE%)...
cd helper
cargo build %CARGO_FLAGS% || goto :error

rmdir /s /q ..\build\windows\helper 2>nul
mkdir ..\build\windows\helper
copy target\%BUILD_MODE%\authenticator-helper.exe ..\build\windows\helper\ || goto :error

echo Generating license files...
cargo about generate about.hbs --config about.toml -o ..\assets\licenses\helper.txt || goto :error

cd ..

echo All done, output in build/windows/
goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
