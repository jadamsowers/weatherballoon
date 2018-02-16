#!/usr/bin/python3

import os, sys, math, time, logging, argparse, json, gpsd, aprs
from Adafruit_BME280 import *


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

	hmsDate = str('%02d' % packet.get_time().day + '%02d' % packet.get_time().hour + '%02d' % packet.get_time().minute) + 'z'

	lat = str(aprs.dec2dm_lat(packet.lat))
	lon = str(aprs.dec2dm_lng(packet.lon))
	track = str('%03d' % math.floor(packet.movement()['track'])) + '/'
	speed = str('%03d' % math.floor(packet.movement()['speed'])) + '/'
	# GPS alt in meters, APRS alt in feet. 1m = 3.28084ft
	alt = 'A=' + str(math.floor(packet.alt * 3.28084)).zfill(6)
	
	# APRS Data type Identifiers: http://www.aprs.org/doc/APRS101.PDF
	#ident = '!' # position without timestamp
	ident = '/' # position with timestamp

	aprsMessage = ident      \
				+ hmsDate    \
				+ lat        \
				+ table      \
				+ lon        \
				+ symbol     \
				+ track      \
				+ speed      \
				+ alt        \
				+ sensorData \
				+ ' ' + custom

	logging.info(str(packet.get_time()) + " Sending APRS message: " + aprsMessage)
	#frame = aprs.Frame(aprsMessage)
	os.system('beacon -d "' + hop + '" -s ' + interface + ' "' + aprsMessage + '"')
	time.sleep(interval)
