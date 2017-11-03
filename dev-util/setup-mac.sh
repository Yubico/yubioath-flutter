# Exit on error
set -e

PY_VERSION="3.6.2"
export MACOSX_DEPLOYMENT_TARGET=10.9

brew update
# Patch PyOtherSide to not be built with debug output
echo "DEFINES += QT_NO_DEBUG_OUTPUT" >> vendor/pyotherside/src/src.pro
pip3 install --upgrade pip

git clone https://github.com/aurelien-rainone/macdeployqtfix.git
brew install qt5 swig ykpers libyubikey hidapi libu2f-host libusb pyenv

# Add qmake to PATH
export PATH="/usr/local/opt/qt/bin:$PATH"

# Build Python 3 with --enable-framework, to be able to distribute it in a .app bundle
brew upgrade pyenv
eval "$(pyenv init -)"
env PYTHON_CONFIGURE_OPTS="--enable-framework CC=clang" pyenv install $PY_VERSION
pyenv global system $PY_VERSION
pip3 install --upgrade pip

# Build and install PyOtherside
cd vendor/pyotherside
qmake
make
sudo make install
cd ../../
qmake
