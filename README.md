# Introduction

This project is the resurrection of an attempt to launch a weather balloon into near-space. All of this code is migrated from a [Google Code](http://code.google.com/p/theraccoonproject) archive. The following came from the wiki articles in the original project.

# Arduino Command Set 
To facilitate easy access to temperature and pressure sensor data, we wrote a small program for the Arduino. 

_Note: by default, the Arduino serial port is configured as 9600 8N1. If you need to use a different speed, update it in the top of the Arduino program before you write it to the device._

|character|description  |
|--|--|
| `h` | Enables human-readable output |
| `r` | Enables raw output (the actual data read from the sensors)|
| `v` | Verbose mode _(status messages will be shown)_ |
| `q` | Quiet mode _(status messages will not be shown)_ |
| `i` | Monitor the inside temperature sensor |
| `o` | Monitor the outside temperature sensor |
| `f` | _if human-readable output is enabled:_ List the temperature in degrees Fahrenheit |
| `c` | _if human-readable output is enabled:_ List the temperature in degrees Celcius |
| `t` | Read data from the temperature sensor |
| `p` | Read data from the pressure sensor |

# Garmin GPS-35LVS

## Serial Connection 
The GPS-35LVS communicates over two serial connections. One transmits mostly diagnostic information and we'll likely ignore it. The other transmits position information in NMEA format.

|Color|Name|Function|
|--|--|--|
|Red|`Vin`| Must be between 3.6 and 6V.|
  |Black|`GND`| Signal ground|
  |White|`TXD1` |Transmit pin for first serial connection (containing NMEA format information)|
|Blue|`RXD1` |Receive pin for first serial connection|
 |Purple|`TXD2` |Transmit pin for second serial connection (provides "phase data information")|
|Green|`RXD2` |Receive pin for the second serial connection|
|Gray|`PPS` |Sends one pulse per second. Useful for very accurate time (not very useful for us.)|
|Yellow|`Power Down` |bringing this high cuts power to the device. The device will restart when this is dropped.|

All we need concern ourselves with are the red, black, white and blue pins.

It may also be useful to run a line to the yellow wire so that we can reset the device if it begins giving spurious information. This could be done either manually or using some sort of automatic sanity checking.

## Interesting Links 

[Technical Specifications](http://www.sintrade.ch/bilder/spec35.pdf)
[Bulletin board thread about connecting to a computer](http://forums.gpscity.com/showthread.php?t=2348) 

# `soundmodem`  config

This is the `soundmodem.conf` file that works with my MacBook. Change the IP, callsign, paths to serial and soundcard, etc. to fit your machine.

File should reside in `/etc/ax25` (create this directory if it doesn't already exist.)

## Details 

```
<?xml version="1.0"?>
<modem>
  <configuration name="sm0">
    <chaccess txdelay="300" slottime="100" ppersist="64" fulldup="0" txtail="30"/>
    <audio type="soundcard" device="/dev/dsp" halfdup="0" capturechannelmode="Mono" simchan="0 - Ideal channel" snr="10" snrmode="0 - White Gaussian" srate="0"/>
    <ptt file="/dev/ttyUSB0"/>
    <channel name="Channel 0">
      <mod mode="afsk" bps="1200" f0="1200" f1="2200" diffenc="1" filter="df9ic/g3ruh"/>
      <demod mode="afsk" bps="1200" f0="1200" f1="2200" diffdec="1"/>
      <pkt mode="MKISS" ifname="sm0" hwaddr="KJ4DEO-1" ip="10.0.0.1" netmask="255.255.255.0" broadcast="10.0.0.255" file="/dev/soundmodem0" unlink="1"/>
    </channel>
  </configuration>
</modem>
```
# TI Temperature Sensor 
Part number: `TMP123AIDBVTG4`
[Datasheet](http://focus.ti.com/lit/ds/symlink/tmp123.pdf)
