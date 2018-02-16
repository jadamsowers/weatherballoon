#!/usr/bin/python3

import os, re, sys, math, time, logging, argparse, json, gpsd, aprs, base91
from Adafruit_BME280 import *

def base91(val, len):
	a    = math.floor(val  / 91**3)
	amod = val % 91**3
	b    = math.floor(amod / 91**2)
	bmod = amod % 91**2
	c    = math.floor(bmod / 91)
	d    = bmod % 91
	return ("".join(list(map(lambda x: chr(x + 33), [a,b,c,d]))))[-len:]

def compressLat(lat):
	return base91(math.floor(380926 * ( 90 - lat)), 4)

def compressLon(lon):
	return base91(math.floor(190463 * (180 + lon)), 4)

def compressAlt(alt):
	return base91(round(math.log(alt) / math.log(1.002)), 2)
	 

os.system('clear')
parser = argparse.ArgumentParser()
parser.add_argument('-c', '--config', default="config.json", help="Path to the configuration file")
parser.add_argument('-d', '--debug', help="Send debug information to console", action="store_true")
args = parser.parse_args()

# thread about APRS WIDE#-# hops 
# http://www.tapr.org/pipermail/aprssig/2014-May/043317.html

# finding your APRS symbol
# https://web.archive.org/web/20101130031326/http://wa8lmf.net/miscinfo/APRS_Symbol_Chart.pdf 

if (args.debug):
	logging.basicConfig(level=logging.DEBUG,format='%(levelname)s:%(message)s')
else:
	logging.basicConfig(level=logging.INFO,format='%(levelname)s:%(message)s')

logging.info("Starting up weather balloon APRS payload")
logging.info("Loading configuration from " + args.config)
config = json.load(open(args.config))
logging.debug("Config file:\n" + json.dumps(config, indent=2, sort_keys=True))

callsign = config["aprs"]["callsign"]
symbol = config["aprs"]["symbol"]
table = config["aprs"]["table"]
interface = config["aprs"]["interface"]
hop = config["aprs"]["hop"]
custom = config["aprs"]["custom"]

announce = "> " + callsign + " weather balloon " + custom
logging.debug(announce)

logging.info("Sending APRS announcement")
os.system('beacon -d "' + hop + '" -s ' + interface + ' "' + announce + '"')

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

	sensor = BME280(t_mode=BME280_OSAMPLE_8, p_mode=BME280_OSAMPLE_8, h_mode=BME280_OSAMPLE_8)
	degrees = sensor.read_temperature()
	pascals = sensor.read_pressure()
	hectopascals = pascals / 100

	sensorData = ' T=' + '{0:.2f}'.format(degrees) + ", P=" + '{0:.2f}'.format(hectopascals)
	logging.debug(sensorData)

	dhmDate = str('%02d' % packet.get_time().day + '%02d' % packet.get_time().hour + '%02d' % packet.get_time().minute) + 'z'

	lat = str(aprs.dec2dm_lat(packet.lat))
	lon = str(aprs.dec2dm_lng(packet.lon))
	track = str('%03d' % math.floor(packet.movement()['track'])) + '/'
	speed = str('%03d' % math.floor(packet.movement()['speed'])) + '/'
	# GPS alt in meters, APRS alt in feet. 1m = 3.28084ft
	alt = 'A=' + str(math.floor(packet.alt * 3.28084)).zfill(6)
	
	# APRS Data type Identifiers: http://www.aprs.org/doc/APRS101.PDF
	#ident = '!' # position without timestamp
	ident = '/' # position with timestamp

	base91pos   = table \
				+ compressLat(packet.lat) \
				+ compressLon(packet.lon) \
				+ symbol \
				+ compressAlt(packet.alt * 3.28084) \
				+ 'S'

	logging.info(base91pos)

	'''
	aprsMessage = ident      \
				+ dhmDate    \
				+ lat        \
				+ table      \
				+ lon        \
				+ symbol     \
				+ track      \
				+ speed      \
				+ alt        \
				+ sensorData \
				+ ' ' + custom
	'''
	aprsMessage = ident + dhmDate + base91pos + custom

	logging.info(str(packet.get_time()) + " Sending APRS message: " + aprsMessage)
	#frame = aprs.Frame(aprsMessage)
	os.system('beacon -d "' + hop + '" -s ' + interface + ' "' + aprsMessage + '"')
	time.sleep(interval)
