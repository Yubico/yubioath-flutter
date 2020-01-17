FROM ubuntu:xenial
RUN apt-get update -qq \
    && apt-get install -qq software-properties-common \
    && add-apt-repository -y ppa:yubico/stable \
    && add-apt-repository -y ppa:beineri/opt-qt-5.12.3-xenial \
    && apt-get -qq update \
    && apt-get -qq upgrade
RUN apt-get install -y git make build-essential libssl-dev zlib1g-dev libbz2-dev \
    devscripts equivs python3-dev python3-pip python3-venv wget fuse \
    qt512base qt512declarative qt512xmlpatterns qt512script qt512tools qt512multimedia \
    qt512svg qt512graphicaleffects qt512imageformats qt512translations qt512quickcontrols \
    qt512sensors qt512serialbus qt512serialport qt512x11extras qt512quickcontrols2 \
    qt512connectivity qt512scxml qt512wayland qt512remoteobjects qtbase5-dev \
    desktop-file-utils libglib2.0-bin qtchooser python3-pip python mesa-common-dev curl swig \
    libpcsclite-dev libffi-dev libykpers-1-1
ENV QT_BASE_DIR=/opt/qt512 \
    QT_DIR=/opt/qt512 \
    QT_BASE_DIR=/opt/qt512 \
    PYTHON_CFLAGS=-fPIC \
    PYTHON_CONFIGURE_OPTS=--enable-shared
ENV LD_LIBRARY_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH \
    PKG_CONFIG_PATH=$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH \
    PATH=/root/.pyenv/bin:$QT_BASE_DIR/bin:$PATH
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && eval "$(pyenv init -)" \
    && pyenv update \
    && pyenv install --force 3.7.4 \
    && pyenv global 3.7.4 \
    && wget https://github.com/thp/pyotherside/archive/1.5.8.tar.gz \
    && tar -xzvf 1.5.8.tar.gz \
    && echo "DEFINES += QT_NO_DEBUG_OUTPUT" >> pyotherside-1.5.8/src/src.pro \
    && cd pyotherside-1.5.8/src \
    && qmake \
    && make \
    && make install
COPY . yubioath-desktop
RUN mkdir -p yubioath-desktop/appDir/usr \
    && eval "$(pyenv init -)" \
    && pyenv global 3.7.4 \
    && cd yubioath-desktop \
    && pip3 install --upgrade pip \
    && pip3 install -r requirements.txt \
    && cp -R /root/.pyenv/versions/3.7.4/* appDir/usr \
    && apt-get download libykpers-1-1 \
    && dpkg -x libykpers*.deb appDir/ \
    && qmake \
    && make \
    && cp resources/yubioath-desktop.desktop appDir/ \
    && cp resources/icons/com.yubico.yubioath.png appDir/ \
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
