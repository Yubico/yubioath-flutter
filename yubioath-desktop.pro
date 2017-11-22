TEMPLATE = app
QT += qml quick widgets
CONFIG += c++11
SOURCES += main.cpp \
    systemtray.cpp

# Version computation logic:
#
# - If the current commit has a tag starting with "yubioath-desktop-":
#   - The rest of that tag is the version number.
#   - If this version number has only two parts (X.Y), append ".0".
#
# - If the current commit does not have a tag:
#   - Find the closest ancestor commit with a tag starting with
#     "yubioath-desktop-", and use the rest of the tag as the version number.
#     - If this version number has three parts ending with zero (X.Y.0), remove
#       the ".0".
#   - Append ".Z-gCOMMIT", where Z is the number of commits since the tagged
#     ancestor commit and COMMIT is the short commit ID of the current commit
#   - This will always be different from the latest tagged version number, and
#     will always be a prerelease version because of the "-gCOMMIT" suffix
#
# - Finally, if the repository has uncommitted or untracked changes, append
#   "-dirty".
# - For the VERSIONINFO in the Windows resource file, reformat the version
#   number "X.Y.Z[-gCOMMIT][-dirty]" to 4 numeric parts:
#   - Discard the "-gCOMMIT" and "-dirty" suffixes if present
#   - If the "-dirty" suffix was present, append ".0".
#   - If the "-dirty" suffix was not present, append ".1".
GIT_VERSION = $$system(git describe --tags "--match=yubioath-desktop-*" --dirty=-dirty)
# Remove tag prefix
GIT_VERSION ~= s/^v//
GIT_VERSION ~= s/^yubioath-desktop-//

# If version starts with 'X.Y-Z-g*', and X, Y and Z are numeric, reformat it to 'X.Y.Z-g*'
GIT_VERSION ~= s/^([0-9]+\.[0-9]+)-([0-9]+)(-g.*)$/\1.\2\3

# If version starts with 'X.Y.0-Z-g*', and X, Y and Z are numeric, reformat it to 'X.Y.Z-g*'
GIT_VERSION ~= s/^([0-9]+\.[0-9]+)\.0-([0-9]+)(-g.*)$/\1.\2\3

# If version is plain 'X.Y', append '.0'
GIT_VERSION ~= s/^([0-9]+\.[0-9]+)(-dirty)?$/\1.0\2


# This is the verson number for the application,
# will be in info.plist file, about page etc.
VERSION = $$GIT_VERSION

message(Version of this build: $$VERSION)

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

win32|win64 {
  # Strip suffixes from version number
  # Append ".0" if "-dirty" or append ".1" if not "-dirty"
  # Because rc compiler requires only numerals in the version number
  VERSION ~= s/^([0-9]+\.[0-9]+\.[0-9]+).*-dirty$/\1.0
  VERSION ~= s/^([0-9]+\.[0-9]+\.[0-9]+)-.*/\1.1
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
