#!/bin/bash


while :
do
    x=`ps -ef | grep aprs-payload.py | grep -v grep |  awk '{print $2}'`
    if [ -z $x ]
    then
        sleep 5

        echo "Starting APRS payload"
   	/home/pi/berryconda3/bin/python3 /home/pi/weatherballoon/raspberrypi/python/aprs-payload.py --config /home/pi/weatherballoon/raspberrypi/python/config.json 
    fi
done
