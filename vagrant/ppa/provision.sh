#! /usr/bin/env bash

#
#   Vagrant box used to release to ppa
#
sudo apt-get update -qq && apt-get -qq upgrade
sudo apt-get install -qq python-pyscard
sudo apt-get install -qq \
    git \
    pcscd \
    python\
    python3 \
    python-all \
    python3-all \
    python-pip \
    python3-pip \
    python-setuptools \
    python3-setuptools \
    python3-pyscard \
    python-usb \
    python3-usb \
    python-six \
    python3-six \
    python-cryptography \
    python3-cryptography \
    python-click \
    python3-click \
    python-openssl \
    python3-openssl \
    python-setuptools \
    python3-setuptools \
    python-enum34 \
    libykpers-1-1 \
    libu2f-host0 \
    debhelper \
    devscripts \
    dh-make \
    gnupg2 \
    gnupg-agent \
    scdaemon

sudo -u ubuntu git clone https://github.com/dainnilsson/scripts
