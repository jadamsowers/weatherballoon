#!/usr/bin/python3

import sys, time, logging, argparse, json, gpsd, aprs

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

config = json.load(open(args.config))
print(config)

#frame = aprs.parse_frame(parser.callsign + ">APRS:>Weather balloon")

# connect to local gpsd instance
logging.info('Connecting to gpsd')
gpsd.connect()

logging.info('Waiting for 3D GPS fix')
time.sleep(5)
packet = gpsd.get_current()
while packet.mode < 3:
	logging.info('still waiting...')
	time.sleep(5)

while True:
	
	packet = gpsd.get_current()
	logging.debug(packet)
	
	time.sleep(args.interval)
