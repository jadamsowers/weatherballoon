#!/bin/bash

echo "Enabling SPI (requires reboot)"
cat /boot/config.txt | sudo sed -e 's/\#\(dtparam=spi=on\)/\1/' > /boot/config.txt

echo "Removing serial console (requires reboot)"
cat /boot/cmdline.txt | sudo sed -e 's/console=serial0,115200 //' > /boot/cmdline.txt

sudo apt-get install python3 gpsd gpsd-clients
sudo pip install gpsd-py3 kiss==6.5.0 aprs==6.5.0

