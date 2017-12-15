#! /usr/bin/env bash

# Install development dependencies
sudo apt-get update -qq
sudo apt-get install -qq software-properties-common
sudo add-apt-repository -y ppa:yubico/stable
sudo apt-get update -qq && apt-get -qq upgrade
sudo apt-get install -qq \
    virtualbox-guest-dkms \
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
    qt5-default \
    qml-module-qtquick-controls \
    qml-module-qtquick-dialogs \
    qml-module-io-thp-pyotherside \
    qml-module-qt-labs-settings \
    python3-pip \
    python3-dev \
    yubikey-manager \
    xfce4 \
    firefox
pip3 install --upgrade pip

# Install flake8 for linting
pip3 install pre-commit flake8

# Fix permissions in repo, install pre-commit hook
cd /vagrant && chown -R ubuntu . && pre-commit install

# Set a root password to enable login from GUI
# Do startx after login to launch xfce4
sudo echo "root:root" | sudo chpasswd

# Make ubuntu user passwordless
sudo passwd -d ubuntu
