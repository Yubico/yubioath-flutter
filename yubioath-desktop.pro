TEMPLATE = app
QT += qml quick widgets
CONFIG += c++11
unix {
  QMAKE_CXXFLAGS += -pedantic-errors
}
SOURCES += main.cpp \
    systemtray.cpp

# This is the verson number for the application,
# will be in info.plist file, about page etc.

PYTHON3_BINARY_NAME=python3
win32|win64 {
  PYTHON3_BINARY_NAME=python
}

VERSION = $$system($$PYTHON3_BINARY_NAME compute-version.py -f VERSION yubioath-desktop-)

message(Version of this build: $$VERSION)

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

win32|win64 {
  # Strip suffixes from version number
  # Append ".0" if "-dirty" or append ".1" if not "-dirty"
  # Because rc compiler requires only numerals in the version number
  VERSION ~= s/^([0-9]+\.[0-9]+\.[0-9]+).*-dirty$/\1.0
  VERSION ~= s/^([0-9]+\.[0-9]+\.[0-9]+)(-.*)?/\1.1
  message(Version tweaked for Windows build: $$VERSION)
}

buildqrc.commands = python build_qrc.py ${QMAKE_FILE_IN}
buildqrc.input = QRC_JSON
buildqrc.output = ${QMAKE_FILE_IN_BASE}.qrc
buildqrc.variable_out = RESOURCES

QMAKE_STRIPFLAGS_LIB  += --strip-unneeded

QMAKE_EXTRA_COMPILERS += buildqrc
QRC_JSON = resources.json

# Generate first time
system(python build_qrc.py resources.json)

# Install python dependencies with pip on mac and win
win32|macx {
    pip.target = pymodules
    QMAKE_EXTRA_TARGETS += pip
    PRE_TARGETDEPS += pymodules
    QMAKE_CLEAN += -r pymodules
}
macx {
    pip.commands = python3 -m venv pymodules && source pymodules/bin/activate && pip3 install -r requirements.txt && deactivate
}
win32 {
    pip.commands = pip3 install -r requirements-win.txt --target pymodules
}

# Default rules for deployment.
include(deployment.pri)

# Mac doesn't use qSingleApplication
!macx {
    include(vendor/qt-solutions/qtsingleapplication/src/qtsingleapplication.pri)
}

# Icon file
RC_ICONS = resources/icons/yubioath.ico

# Mac specific configuration
macx {
    ICON = resources/icons/yubioath.icns
    QMAKE_INFO_PLIST = resources/mac/Info.plist.in
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9 # Mavericks
    QMAKE_POST_LINK += cp -rnf pymodules/lib/python3*/site-packages/ yubioath-desktop.app/Contents/MacOS/pymodules/
}

# For generating a XML file with all strings.
lupdate_only {
  SOURCES = qml/*.qml \
  qml/slot/*.qml
}

HEADERS += screenshot.h \
    systemtray.h

DISTFILES += \
    py/* \
    py/qr/* \
    qml/*
