#!/bin/bash

echo "Enabling SPI and UART (requires reboot)"
sudo sed -i 's/\#\(dtparam=spi=on\)/\1/' /boot/config.txt
echo "enable_uart=1" >> /boot/config.txt

echo "Removing serial console (requires reboot)"
sudo sed -i 's/console=serial0,115200 //' /boot/cmdline.txt

echo "Installing dependencies"
sudo apt-get install python3 gpsd gpsd-clients ax25-tools ax25-apps

echo "Installing Berryconda"
wget https://github.com/jjhelmus/berryconda/releases/download/v2.0.0/Berryconda3-2.0.0-Linux-armv7l.sh
chmod +x Berryconda3-2.0.0-Linux-armv7l.sh
./Berryconda3-2.0.0-Linux-armv7l.sh -b

echo "Installing python plugins"
sudo ~/berryconda3/bin/pip install gpsd-py3 aprs

echo "Installing python libraries for sensor"
git clone https://github.com/adafruit/Adafruit_Python_GPIO.git
cd Adafruit_Python_GPIO
sudo ~/berryconda3/bin/python setup.py install
git clone https://github.com/adafruit/Adafruit_Python_BME280.git
cd Adafruit_Python_BME280
sudo ~/berryconda3/bin/python setup.py install

echo "Installing pi-tnc apps"
wget http://tnc-x.com/pitnc.zip
unzip pitnc.zip
chmod +x pitnc_*
sudo mv pitnc_* /usr/local/sbin
wget http://tnc-x.com/i2ckiss.zip
unzip i2ckiss.zip
chmod +x i2ckiss
sudo mv i2ckiss /usr/local/sbin

echo "Setting up gpsd"
sudo service gpsd stop
sudo sed -i 's/DEVICES=\"\"/DEVICES=\"\/dev\/ttyAMA0\"/' /etc/default/gpsd
sudo service gpsd start


#TODO: set up /etc/ax25/axports
