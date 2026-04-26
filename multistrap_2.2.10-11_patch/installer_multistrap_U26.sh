#!/bin/bash

sudo apt-get install libconfig-auto-perl libparse-debian-packages-perl || exit 1

wget https://archive.ubuntu.com/ubuntu/pool/universe/m/multistrap/multistrap_2.2.11_all.deb || exit 1

sudo dpkg -i multistrap_2.2.11_all.deb || exit 1

sudo cp multistrap /usr/sbin/multistrap

exit 0

