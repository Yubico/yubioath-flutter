FROM ubuntu:xenial
RUN apt-get update -qq \
    && apt-get install -qq software-properties-common \
    && add-apt-repository -y ppa:yubico/stable \
    && add-apt-repository -y ppa:beineri/opt-qt-5.11.2-xenial \
    && apt-get -qq update \
    && apt-get -qq upgrade
RUN apt-get install -y git make build-essential libssl-dev zlib1g-dev libbz2-dev \
    devscripts equivs python3-dev python3-pip python3-venv wget fuse \
    qt511base qt511declarative qt511xmlpatterns qt511script qt511tools qt511multimedia \
    qt511svg qt511graphicaleffects qt511imageformats qt511translations qt511quickcontrols \
    qt511sensors qt511serialbus qt511serialport qt511x11extras \
    qt511connectivity qt511scxml qt511wayland qt511remoteobjects qt511creator qtbase5-dev \
    desktop-file-utils libglib2.0-bin qtchooser python3-pip python mesa-common-dev curl swig \
    libpcsclite-dev libffi-dev libykpers-1-1
ENV QT_BASE_DIR=/opt/qt511 \
    QT_DIR=/opt/qt511 \
    QT_BASE_DIR=/opt/qt511 \
    PYTHON_CFLAGS=-fPIC \
    PYTHON_CONFIGURE_OPTS=--enable-shared
ENV LD_LIBRARY_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH \
    PKG_CONFIG_PATH=$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH \
    PATH=/root/.pyenv/bin:$QT_BASE_DIR/bin:$PATH
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && eval "$(pyenv init -)" \
    && pyenv update \
    && pyenv install --force 3.6.5 \
    && pyenv global 3.6.5 \
    && wget https://github.com/thp/pyotherside/archive/1.5.3.tar.gz \
    && tar -xzvf 1.5.3.tar.gz \
    && echo "DEFINES += QT_NO_DEBUG_OUTPUT" >> pyotherside-1.5.3/src/src.pro \
    && cd pyotherside-1.5.3/src \
    && qmake \
    && make \
    && make install
COPY . yubioath-desktop
RUN mkdir -p yubioath-desktop/appDir/usr \
    && eval "$(pyenv init -)" \
    && pyenv global 3.6.5 \
    && cd yubioath-desktop \
    && pip3 install --upgrade pip \
    && pip3 install -r requirements.txt \
    && cp -R /root/.pyenv/versions/3.6.5/* appDir/usr \
    && apt-get download libykpers-1-1 \
    && dpkg -x libykpers*.deb appDir/ \
    && qmake \
    && make \
    && cp resources/yubioath-desktop.desktop appDir/ \
    && cp resources/icons/yubioath.png appDir/ \
    && cp ./yubioath-desktop appDir/usr/bin/ \
    && wget -c "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" \
    && wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
    && chmod a+x linuxdeployqt*.AppImage \
    && chmod a+x appimagetool*.AppImage \
    && unset QTDIR \
    && unset QT_PLUGIN_PATH \
    && unset LD_LIBRARY_PATH
CMD cd yubioath-desktop \
    && ./linuxdeployqt*.AppImage appDir/usr/bin/yubioath-desktop -qmldir=./qml -bundle-non-qt-libs \
    && rm appDir/AppRun \
    && cp ./resources/linux/AppRun appDir/ \
    && chmod a+x appDir/AppRun \
    && ./appimagetool*.AppImage appDir
