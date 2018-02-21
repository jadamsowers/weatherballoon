#!/usr/bin/python3

import os, re, sys, math, time, logging, argparse, json, gpsd, aprs, base91 , subprocess, Adafruit_BME280
from APRS_helpers import *
	 

os.system('clear')
parser = argparse.ArgumentParser()
parser.add_argument('-c', '--config', default="config.json", help="Path to the configuration file")
parser.add_argument('-d', '--debug', help="Send debug information to console", action="store_true")
args = parser.parse_args()

# thread about APRS WIDE#-# hops 
# http://www.tapr.org/pipermail/aprssig/2014-May/043317.html

# finding your APRS symbol
# http://www.aprs.org/symbols/symbols-new.txt 

if (args.debug):
	logging.basicConfig(level=logging.DEBUG,format='%(levelname)s:%(message)s')
else:
	logging.basicConfig(level=logging.INFO,format='%(levelname)s:%(message)s')

logging.info("Starting up weather balloon APRS payload")
logging.info("Loading configuration from " + args.config)
config = json.load(open(args.config))
logging.debug("Config file:\n" + json.dumps(config, indent=2, sort_keys=True))

callsign         = config["aprs"]["callsign"]
symbol           = config["aprs"]["symbol"]
table            = config["aprs"]["table"]
interface        = config["aprs"]["interface"]
hop              = config["aprs"]["hop"]
custom           = config["aprs"]["custom"]
seaLevelhPa      = float(config["general"]["seaLevelhPa"])

announce = "> " + callsign + " weather balloon " + custom
logging.debug(announce)

logging.info("Sending APRS announcement")
sendBeacon(['-d', hop, '-s', interface , announce])

# connect to local gpsd instance
logging.info('Connecting to gpsd')
gpsd.connect()

logging.info('Connected to gpsd. Waiting for 3D GPS fix')
packet = gpsd.get_current()
while packet.mode < 3:
	logging.info('still waiting...')
	time.sleep(5)
	packet = gpsd.get_current()

logging.info('3D GPS fix found. Current position: ' + str(packet.position()))

interval = int(config["aprs"]["interval"])
while True:
	packet = gpsd.get_current()
	logging.debug(packet)

	sensor = Adafruit_BME280.BME280( \
			t_mode=Adafruit_BME280.BME280_OSAMPLE_8, \
			p_mode=Adafruit_BME280.BME280_OSAMPLE_8, \
			h_mode=Adafruit_BME280.BME280_OSAMPLE_8)
	degrees = sensor.read_temperature()
	hectoPascals = pascals = sensor.read_pressure() / 100

	altitude = 44330 * (1.0 - pow(float(hectoPascals) / seaLevelhPa, 0.1903))
	logging.debug("Estimated altitude from pressure: " + str(altitude) + ". GPS altitude: " + str(packet.alt) + ".")

	sensorData = ' T=' + '{0:.2f}'.format(degrees) + ", P=" + '{0:.2f}'.format(hectoPascals)
	logging.debug(sensorData)

	dhmDate = str('%02d' % packet.get_time().day + '%02d' % packet.get_time().hour + '%02d' % packet.get_time().minute) + 'z'

	
	# APRS Data type Identifiers: http://www.aprs.org/doc/APRS101.PDF
	#ident = '!' # position without timestamp
	ident = '/' # position with timestamp

	
	
	base91Lat = compressLat(packet.lat)
	base91Lon = compressLon(packet.lon)
	# GPS alt in meters, APRS alt in feet. 1m = 3.28084ft
	base91alt = compressAlt(packet.alt * 3.28084)

	base91pos   = table \
				+ base91Lat \
				+ base91Lon \
				+ symbol \
				+ base91alt \
				+ 'S' # see below

	''' 
		Why 'S'? 
	    'S' is ASCII 83
		Subtracting '!' (ASCII 33) yields 50
		    bit   7 6 5 43 210
				  ------------
		50(dec) = 0 0 1 10 010  (bin)
		          | | |  |   +- Compression origin: software
                  | | |  +----- NMEA source: GGA (contains altitude value)
				  | | +-------- GPS Fix: current
				  | +---------- (Unused)
                  +------------ (Unused) 
	'''

	logging.info('Position: (' \
				+ str(packet.lat) + ', ' \
				+ str(packet.lon) + ') (' \
				+ str(packet.alt) + 'm) => "' \
				+ base91pos + '"')

	aprsMessage = ident + dhmDate + base91pos + custom

	logging.info(str(packet.get_time()) + " Sending APRS message: " + aprsMessage)
	#frame = aprs.Frame(aprsMessage)
	#os.system('beacon -d "' + hop + '" -s ' + interface + ' "' + aprsMessage + '"')
	arguments = ['-d', hop, '-s', interface , aprsMessage]
	logging.debug(arguments)
	sendBeacon(arguments)

	time.sleep(interval)
