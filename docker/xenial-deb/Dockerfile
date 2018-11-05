FROM ubuntu:xenial
RUN apt-get update -qq
RUN apt-get install -qq software-properties-common
RUN add-apt-repository -y ppa:yubico/stable
RUN apt-get -qq update && apt-get -qq upgrade && apt-get install -y git devscripts equivs python3-dev python3-pip
COPY . yubioath-desktop
RUN yes | mk-build-deps -i /yubioath-desktop/debian/control
RUN cd yubioath-desktop && debuild -us -uc
RUN mkdir /deb && mv /yubioath-desktop_* /deb
RUN cd / && tar czf yubioath-desktop-debian-packages.tar.gz deb
RUN git clone https://github.com/Yubico/yubikey-manager
RUN yes | mk-build-deps -i /yubikey-manager/debian/control
RUN cd yubikey-manager && debuild -us -uc
RUN mv /yubikey-manager_* /python3-yubikey-manager_* /python-yubikey-manager_* /deb
