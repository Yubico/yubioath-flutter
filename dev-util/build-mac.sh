#!/bin/bash

# Exit on error
set -e

# Add qmake to PATH
export PATH="/usr/local/opt/qt/bin:$PATH"
PY_VERSION="3.6.3"
APP_DIR=yubioath-desktop.app

VERSION=${TRAVIS_BRANCH:-$(python3 compute-version.py yubioath-desktop-)}

qmake
make

mkdir -p deploy/

# Exctract all user facing strings and create a textfile with them for deployment.
lupdate yubioath-desktop.pro -ts yubioath-desktop.ts
cp yubioath-desktop.ts deploy/yubioath-desktop-$VERSION-strings.xml
macdeployqt "${APP_DIR}"/ -qmldir=qml/

# Copy needed dylibs
find /usr/local/Cellar/json-c/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/ykpers/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/libyubikey/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/hidapi/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/libu2f-host/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/libusb/ -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'
find /usr/local/Cellar/openssl/1.0.2m -name '*.dylib' -exec cp '{}' "${APP_DIR}"/Contents/Frameworks/ ';'

# Copy Python framework
cp -an ~/.pyenv/versions/$PY_VERSION/Python.framework "${APP_DIR}"/Contents/Frameworks/
find "${APP_DIR}"/Contents/Frameworks/Python.framework -name '*.pyc' -delete
find "${APP_DIR}"/Contents/Frameworks/Python.framework -name '__pycache__' -delete

# Move pymodules from app bundle to site-packages, to be accepted by codesign
mv "${APP_DIR}"/Contents/MacOS/pymodules/* "${APP_DIR}"/Contents/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages/ || echo 'Failure, but continuing anyway...'
rm -rf "${APP_DIR}"/Contents/MacOS/pymodules

# Fix Python library path (macdeployqtfix fails to do this when running locally)
install_name_tool -change /usr/local/opt/python3/Frameworks/Python.framework/Versions/3.6/Python @executable_path/../Frameworks/Python.framework/Versions/3.6/Python "${APP_DIR}"/Contents/PlugIns/quick/libpyothersideplugin.dylib

# Fix dylib writable permissions
find "${APP_DIR}" -name '*.dylib' -exec chmod u+w {} \;

# Fix stuff that macdeployqt does incorrectly.
python macdeployqtfix/macdeployqtfix.py "${APP_DIR}"/Contents/MacOS/yubioath-desktop /usr/local
#python macdeployqtfix/macdeployqtfix.py "${APP_DIR}"/Contents/MacOS/ykman-gui /usr/local/Cellar/python3/$PY_VERSION/Frameworks
#python macdeployqtfix/macdeployqtfix.py "${APP_DIR}"/Contents/MacOS/ykman /usr/local/Cellar/python3/$PY_VERSION/Frameworks

# Fix linking for PyOtherSide
install_name_tool -change ~/.pyenv/versions/$PY_VERSION/Python.framework/Versions/3.6/Python @executable_path/../Frameworks/Python.framework/Versions/3.6/Python "${APP_DIR}"/Contents/Resources/qml/io/thp/pyotherside/libpyothersideplugin.dylib

# Fix linking for Python _ssl
install_name_tool -change /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib @executable_path/../Frameworks/libcrypto.1.0.0.dylib "${APP_DIR}"/Contents/Frameworks/Python.framework/Versions/3.6/lib/python3.6/lib-dynload/_ssl.cpython-36m-darwin.so
install_name_tool -change /usr/local/opt/openssl/lib/libssl.1.0.0.dylib @executable_path/../Frameworks/libssl.1.0.0.dylib "${APP_DIR}"/Contents/Frameworks/Python.framework/Versions/3.6/lib/python3.6/lib-dynload/_ssl.cpython-36m-darwin.so

# Fix linking for Python _hashlib
install_name_tool -change /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib @executable_path/../Frameworks/libcrypto.1.0.0.dylib "${APP_DIR}"/Contents/Frameworks/Python.framework/Versions/3.6/lib/python3.6/lib-dynload/_hashlib.cpython-36m-darwin.so
install_name_tool -change /usr/local/opt/openssl/lib/libssl.1.0.0.dylib @executable_path/../Frameworks/libssl.1.0.0.dylib "${APP_DIR}"/Contents/Frameworks/Python.framework/Versions/3.6/lib/python3.6/lib-dynload/_hashlib.cpython-36m-darwin.so

# Copy .app to deploy dir
tar -czf deploy/yubioath-desktop-$VERSION.app.tar "${APP_DIR}"
