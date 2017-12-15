#! /usr/bin/env bash

sudo apt-get install -qq gnome-shell
sudo systemctl enable gdm
sudo systemctl start gdm
