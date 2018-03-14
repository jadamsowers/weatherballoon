import math, subprocess

def intToBase91(val, len):
	if(len == 1):
		return chr(val + ord('!'))
	else:
		a = int(val / 91 ** (len-1))
		b =     val % 91 ** (len-1)
		return chr(a + ord('!')) + intToBase91(b, len-1)

def base91ToInt(val):
	if(len(val)):
		a = ord(val[-1:]) - 33
		return a + 91 * base91ToInt(val[:-1])
	else: 
		return 0

def encodeLat(lat):
	return int(380926 * (90 - lat))

def decodeLat(lat):
	return 90 - lon / 380926


def encodeLon(lon):
	return int(190463 * (180 + lon))

def decodeLon(lon):
	return lon / 190463 - 180


def encodeAlt(alt):
	return round(math.log(alt) / math.log(1.002))

def decodeAlt(alt):
	return math.pow(1.002, alt)


def compressLat(lat):
	return intToBase91(encodeLat(lat), 4)

def compressLon(lon):
	return intToBase91(encodeLon(lon), 4)

def compressAlt(alt):
	return intToBase91(encodeAlt(alt), 2)

def sendBeacon(args):
	command = ["beacon"]
	command.extend(args)
	return subprocess.Popen(command)