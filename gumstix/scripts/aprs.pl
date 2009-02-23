#!/usr/bin/perl
# This script adapted from http://vpizza.org/~jmeehan/balloon/aprs.txt
#
# J. Adam Sowers, David Wilson, Bryan Knight
# http://www.theraccoonproject.org/


use IO::Socket;
use IO::Select;
use IO::File;

# gpsd host/socket
$GPSDHOST = "127.0.0.1";
$GPSDPORT = "2947";

# logging information (might want to store this on external media)
$LOGDIR 	= "/var/log";
$APRSLOG 	= "aprs.log";
$PTLOG		= "pt_data.log";

# find the appropriate APRS symbol for your project here:
# http://wa8lmf.net/miscinfo/APRS_Symbol_Chart.pdf
$SYMBOLTABLE="/";
$MAPCHAR = "O"; 

# Enter whatever text you want here 
# it will appear at the end of the beacon string.
$CUSTOM = "WX Balloon theraccoonproject.org";
$DEBUG = 0;  

# This must match the interface you defined in /etc/ax25/axports
$INTERFACE= 1;

$loginterval = 15;
$beaconcounter = $beaconmultiple = 4;

sub debug
{
  if($DEBUG) 
  {
    local($debugstr) = @_;
    print "DEBUG: " . $debugstr . "\n";
  }
}

sub gps_command 
{
  my @ready, $s, $buf;
  my $handle = shift(@_);
  my $command = shift(@_);
  my $read_set = new IO::Select($handle);
  print $handle "$command\n";
  while (1) {
    if (@ready = $read_set->can_read(2)) {
      foreach $s (@ready) {
        $buf = <$s>;
        if ($buf =~ m/GPSD/) {
          return $buf;
        }
      }
    }
    else {
      return 0;
    }
  }        
}

sub getTempPressureData
{
  $latest = `tail -n 1 $LOGDIR/$PTLOG`;
  debug("PT log: $latest");
  $latest =~ m/([\d]+) (.*)/;
  
  $time = `date "+%Y%m%d%H%M%S"`;
  chomp($time);

  # check to make sure the data is fresh
  if(($time - $1) < 30)
  {
    $pt = $2;
    debug($pt);
    return $pt;
  }
  else
  {
    return "NO PT DATA";
  }
}
               
$| = 1;

$aprslog = new IO::File(">>$LOGDIR/$APRSLOG");
die "Could not open log file: $!\n" unless $aprslog;
$aprslog->autoflush(1);

$opencount = 0;
while ((! $gpsd) && ($opencount < 30)) {
  $gpsd = new IO::Socket::INET
            (PeerAddr => $GPSDHOST,
             PeerPort => $GPSDPORT,
             Proto    => 'tcp',);
  $opencount++;
  sleep 1;
}
die "Could not create socket: $!\n" unless $gpsd;
$gpsd->autoflush(1);


while (1) {
  $gps_okay = 1;

  # try to determine the NMEA status
  # 0: no fix, 1: fix, 2: DGPS-corrected fix (newer GPSes support this)
  if ($gps_okay = (($result = gps_command($gpsd, "s")) ? (1 && $gps_okay) : 0)) 
  {
    $result =~ m/GPSD,S=([012])/;
    $gps_valid = $1;
  }

  # get the date/time from the GPS (we only care about the time)
  if ($gps_okay = (($result = gps_command($gpsd, "d")) ? (1 && $gps_okay) : 0)) 
  {
    $result =~ m/GPSD,D=(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
    $gps_utc = $4 . $5 . $6;
  }
  
  # get the position from the GPS
  if ($gps_okay = (($result = gps_command($gpsd, "p")) ? (1 && $gps_okay) : 0)) 
  {
	# the GPS gives us the position in decimal degrees, e.g., 
	#    37.12345 -78.98765
	# APRS however expects the position in degrees, decimal minutes, e.g., 
	#    37 07.407N 78 59.259W
	# so we need to convert it.
	
    $result =~ m/GPSD,P=(\-?)([\d\.]+) (\-?)([\d\.]+)/; 
    $gps_lat_dir = $1 ? "S" : "N";
    $gps_lon_dir = $3 ? "W" : "E";

    $gps_lat_deg = int($2);
    $gps_lon_deg = int($4);
 
    # get the decimal degrees portion and convert it to minutes
	$gps_lat_min = ($2 - int($2)) * 60;
    $gps_lon_min = ($4 - int($4)) * 60;

	# get the decimal minutes portion (vars will be in the form 0.xxxxxx)
    $gps_lat_min_dec = ($gps_lat_min - int($gps_lat_min));
    $gps_lon_min_dec = ($gps_lon_min - int($gps_lon_min));

	# lop off the initial 0 
    $gps_lat_min_dec =~ s/^\d//;
    $gps_lon_min_dec =~ s/^\d//;

	# pad the minutes field in case it's a single digit
    $gps_lat = $gps_lat_deg . sprintf("%02d", $gps_lat_min) .  $gps_lat_min_dec;
    $gps_lon = $gps_lon_deg . sprintf("%02d", $gps_lon_min) .  $gps_lon_min_dec;

    debug($gps_lat_dir . $gps_lat . " " . $gps_lon_dir . $gps_lon);
  }

  if ($gps_okay = (($result = gps_command($gpsd, "v")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,V=([\d\.]+)/; 
    $gps_speed = $1;
  }
  if ($gps_okay = (($result = gps_command($gpsd, "t")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,T=([\d\.]+)/;
    $gps_heading = $1;
  }
  if ($gps_okay = (($result = gps_command($gpsd, "a")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,A=([\d\.]+)/;
    $gps_alt = $1 * 3.28;
  }

  $aprs_string = sprintf("\=%.6dh%07.2f%s%s%08.2f%s%s%.3d/%.3d/A=%.6d", 
		$gps_utc, 
		$gps_lat, 
		$gps_lat_dir, 
		$SYMBOLTABLE, 
		$gps_lon, 
		$gps_lon_dir, 
		$MAPCHAR, 
		$gps_heading, 
		$gps_speed, 
		$gps_alt);
  $aprs_string = $aprs_string." INVALID" unless $gps_valid;
  $aprs_string = $aprs_string." GPSERROR" unless $gps_okay;
  $aprs_string .= " " . getTempPressureData();
  debug("APRS string: $aprs_string");

  print $aprslog "$aprs_string\n";

  if ($beaconcounter >= $beaconmultiple) {
    $aprs_string = $aprs_string. " " . $CUSTOM;
    system("beacon -d \"APRS VIA WIDE2-2\" -s $INTERFACE \"$aprs_string\"");
    $beaconcounter = 1;
  }
  else {
    $beaconcounter++;
  }
  sleep $loginterval;
}                                 
