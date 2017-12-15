#!/bin/bash

sudo yum install -y \
  @xfce-desktop-environment \
  gcc-c++\
  pcsc-lite \
  pyotherside \
  qt5-devel \
  qt5-qtquickcontrols \
  yubioath-desktop

# Make vagrant user passwordless
sudo passwd -d vagrant
