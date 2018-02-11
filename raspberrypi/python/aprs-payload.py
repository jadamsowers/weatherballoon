import sys, time, logging, argparse, gpsd, aprs

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--interval', type=int, default=30, help="The interval (in seconds) to send APRS updates") 
parser.add_argument('-c', '--callsign', help="The amateur radio callsign to send")
parser.add_argument('-d', '--debug', help="Send debug information to console", action="store_true")
parser.add_argument('-t', '--table', choices=['/', '\\'], default='/', help="APRS symbol table to use")
parser.add_argument('-s', '--symbol', default='O', help="APRS symbol to use")
parser.add_argument('--hop', default="WIDE1-1,WIDE2-1", help="APRS digipeater hops requested")
args = parser.parse_args()

# unsure about WIDEn-n hops? 
# http://www.tapr.org/pipermail/aprssig/2014-May/043317.html

if (args.debug):
	logging.basicConfig(level=logging.DEBUG,format='%(levelname)s:%(message)s')
else:
	logging.basicConfig(level=logging.INFO,format='%(levelname)s:%(message)s')
print (args)

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
