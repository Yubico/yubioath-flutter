FROM ubuntu:xenial
RUN apt-get update -qq
RUN apt-get install -qq software-properties-common
RUN add-apt-repository -y ppa:yubico/stable
RUN apt-get update -qq && apt-get -qq upgrade
RUN apt-get install -qq \
    git \
    swig \
    python \
    libpcsclite-dev \
    libssl-dev \
    libffi-dev \
    libykpers-1-1 \
    libu2f-host0 \
    qtbase5-dev \
    qtdeclarative5-dev \
    libqt5svg5-dev \
    python3-dev \
    python3-pip \
    python3-pyscard \
    devscripts \
    debhelper \
    qt5-default \
    qml-module-qtquick-controls \
    qml-module-qtquick-dialogs \
    qml-module-io-thp-pyotherside \
    qml-module-qt-labs-settings \
    python3-pip \
    python3-dev
RUN pip3 install --upgrade pip
COPY . yubioath-desktop
RUN tar xfa yubioath-desktop/ykman-deb.tar.gz
RUN dpkg -i /deb/python3-yubikey-manager_*.deb; exit 0
RUN dpkg -i /deb/yubikey-manager_*.deb; exit 0
RUN apt-get install -f -qq
RUN cd yubioath-desktop && qmake -qt=qt5 && make
RUN cd yubioath-desktop && debuild -us -uc
RUN mv /yubioath-desktop_* /deb
RUN cd / && tar czf yubioath-desktop-debian-packages.tar.gz deb
