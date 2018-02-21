#!/bin/bash


while :
do
    x=`ps -ef | grep i2c | grep -v grep |  awk '{print $2}'`
    if [ -z $x ]
    then
        echo "Killing kissattach processes"
        sudo killall kissattach 

        echo "Resetting TNC"
        sudo pitnc_setparams 1 9 15 2

        sleep 5

        echo "Starting i2ckiss"
        sudo i2ckiss 1 9 1 10.10.10.10
    
        sleep 5
    fi
done