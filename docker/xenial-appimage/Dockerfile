FROM ubuntu:xenial
RUN apt-get update -qq \
    && apt-get install -qq software-properties-common \
    && add-apt-repository -y ppa:yubico/stable \
    && add-apt-repository -y ppa:beineri/opt-qt-5.15.2-xenial \
    && apt-get -qq update \
    && apt-get -qq upgrade
RUN apt-get install -y git make build-essential g++ libssl-dev zlib1g-dev libbz2-dev \
    devscripts equivs python3-dev python3-pip python3-venv wget fuse \
    qt515base qt515declarative qt515xmlpatterns qt515script qt515tools qt515multimedia \
    qt515svg qt515graphicaleffects qt515imageformats qt515translations qt515quickcontrols \
    qt515sensors qt515serialbus qt515serialport qt515x11extras qt515quickcontrols2 \
    qt515connectivity qt515scxml qt515wayland qt515remoteobjects qtbase5-dev \
    desktop-file-utils libglib2.0-bin qtchooser python3-pip python mesa-common-dev curl swig \
    libpcsclite-dev libffi-dev
ENV QT_BASE_DIR=/opt/qt515 \
    QT_DIR=/opt/qt515 \
    PYTHON_CFLAGS=-fPIC \
    PYTHON_CONFIGURE_OPTS=--enable-shared
ENV LD_LIBRARY_PATH=$QT_BASE_DIR/lib/x86_64-linux-gnu:$QT_BASE_DIR/lib:$LD_LIBRARY_PATH \
    PKG_CONFIG_PATH=$QT_BASE_DIR/lib/pkgconfig:$PKG_CONFIG_PATH \
    PATH=/root/.pyenv/bin:$QT_BASE_DIR/bin:$PATH
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && eval "$(pyenv init --path)" \
    && pyenv update \
    && pyenv install --force 3.8.7 \
    && pyenv global 3.8.7 \
    && wget https://github.com/thp/pyotherside/archive/1.5.9.tar.gz \
    && tar -xzvf 1.5.9.tar.gz \
    && echo "DEFINES += QT_NO_DEBUG_OUTPUT" >> pyotherside-1.5.9/src/src.pro \
    && cd pyotherside-1.5.9/src \
    && qmake \
    && make \
    && make install
COPY . yubioath-desktop
RUN mkdir -p yubioath-desktop/appDir/usr \
    && eval "$(pyenv init --path)" \
    && pyenv global 3.8.7 \
    && cd yubioath-desktop \
    && pip3 install --upgrade pip \
    && pip3 install -r requirements.txt \
    && cp -R /root/.pyenv/versions/3.8.7/* appDir/usr \
    && qmake \
    && make \
    && cp resources/com.yubico.yubioath.desktop appDir/ \
    && cp resources/com.yubico.yubioath.appdata.xml appDir/ \
    && cp resources/icons/com.yubico.yubioath.svg appDir/ \
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