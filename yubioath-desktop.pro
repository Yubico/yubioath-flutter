TEMPLATE = app
QT += qml quick widgets quickcontrols2
CONFIG += c++11
CONFIG += qzxing_qml
CONFIG += qzxing_multimedia
SOURCES += main.cpp
HEADERS += screenshot.h

# This is the internal verson number, Windows requires 4 digits.
win32|win64 {
    VERSION = 5.1.0.0
    QMAKE_TARGET_COMPANY = Yubico
    QMAKE_TARGET_PRODUCT = Yubico Authenticator
    QMAKE_TARGET_DESCRIPTION = Yubico Authenticator
    QMAKE_TARGET_COPYRIGHT = Copyright (c) 2020 Yubico AB
} else {
    VERSION = 5.1.0
}
# This is the version shown on the About page
DEFINES += APP_VERSION=\\\"5.1.0-alpha1\\\"

message(Version of this build: $$VERSION)

win32|win64 {
    PYTHON_CMD = python
} else {
    PYTHON_CMD = python3
}

buildqrc.commands = $$PYTHON_CMD build_qrc.py ${QMAKE_FILE_IN}
buildqrc.input = QRC_JSON
buildqrc.output = ${QMAKE_FILE_IN_BASE}.qrc
buildqrc.variable_out = RESOURCES

QMAKE_STRIPFLAGS_LIB  += --strip-unneeded

QMAKE_EXTRA_COMPILERS += buildqrc
QRC_JSON = resources.json

# Generate first time
system($$PYTHON_CMD build_qrc.py resources.json)

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
!macx {
    pip.commands = pip3 install -r requirements.txt --target pymodules
}

# Default rules for deployment.
include(deployment.pri)

# QXZing for QR scanner
include(QZXing/QZXing.pri)

# Icon file
RC_ICONS = resources/icons/com.yubico.yubioath.ico

# Mac specific configuration
macx {
    ICON = resources/icons/com.yubico.yubioath.icns
    QMAKE_INFO_PLIST = resources/mac/Info.plist.in
}

# For generating a XML file with all strings.
lupdate_only {
  SOURCES = qml/*.qml \
  qml/slot/*.qml
}


DISTFILES += \
    py/* \
    py/qr/* \
    qml/* \
