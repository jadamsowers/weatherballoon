#!/usr/bin/perl
#

use IO::Socket;
use IO::Select;
use IO::File;

$DEBUG = 0;   

$host = "127.0.0.1";
$port = "2947";

$logfile = "aprs.log";

$map_char = "O";

$callsign = "KJ4DEO-9";
$email = "adam\@theraccoonproject.org";
$int = 1;

$loginterval = 15;
$beaconcounter = $beaconmultiple = 4;

sub do_command {
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

sub get_temp {
  my $ti, $to;
  my @ready, $s, $buf;
  my $handle = shift(@_);
  my $read_set = new IO::Select($handle);
  print $handle "R4 1\n";
  if (@ready = $read_set->can_read(2)) {
    foreach $s (@ready) {
      $buf = <$s>;
      if ($buf =~ m/(\d+)/) {
        if ($1) {
          $ti = ($1 * .121612 - 273) * 1.8 + 32;
        }
      }
    }
  }
  print $handle "R5 1\n";
  if (@ready = $read_set->can_read(2)) {
    foreach $s (@ready) {
      $buf = <$s>;
      if ($buf =~ m/(\d+)/) {
        if ($1) {
          $to = ($1 * .121612 - 273) * 1.8 + 32;
        }
      }
    }
  }
  return ($ti, $to);
}
                
$| = 1;

$aprslog = new IO::File(">>$logfile");
die "Could not open log file: $!\n" unless $aprslog;
$aprslog->autoflush(1);

while ((! $gpsd) && ($opencount < 30)) {
  $gpsd = new IO::Socket::INET
            (PeerAddr => $host,
             PeerPort => $port,
             Proto    => 'tcp',);
  $opencount++;
  sleep 1;
}
die "Could not create socket: $!\n" unless $gpsd;
$gpsd->autoflush(1);

$opencount  = 0;

#while ((! $admon) && ($opencount < 30)) {
#  $admon = new IO::Socket::INET
#             (PeerAddr => '127.0.0.1',
#              PeerPort => '7070',
#              Proto    => 'tcp',);
#  $opencount++;
#  sleep 1;
#}
#die "Could not create socket: $!\n" unless $admon;
#$admon->autoflush(1); 
#
while (1) {
  $gps_okay = 1;
  if ($gps_okay = (($result = do_command($gpsd, "s")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,S=([012])/;
    $gps_valid = $1;
  }
  if ($gps_okay = (($result = do_command($gpsd, "d")) ? (1 && $gps_okay) : 0)) {
#    $result =~ m/GPSD,D=(\d+)\/(\d+)\/(\d+) (\d+):(\d+):(\d+)/;
    $result =~ m/GPSD,D=(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/;
    $gps_utc = $4 . $5 . $6;
  }
  if ($gps_okay = (($result = do_command($gpsd, "p")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,P=(\-?)([\d\.]+) (\-?)([\d\.]+)/; 
    $gps_lat_dir = $1 ? "S" : "N";
    $gps_lon_dir = $3 ? "W" : "E";

    $gps_lat_deg = int($2);
    $gps_lon_deg = int($4);
 
    $gps_lat_min = ($2 - int($2)) * 60;
    $gps_lon_min = ($4 - int($4)) * 60;

    $gps_lat_min_dec = ($gps_lat_min - int($gps_lat_min));
    $gps_lon_min_dec = ($gps_lon_min - int($gps_lon_min));

    $gps_lat_min_dec =~ s/^\d//;
    $gps_lon_min_dec =~ s/^\d//;

    $gps_lat = $gps_lat_deg . sprintf("%02d", $gps_lat_min) .  $gps_lat_min_dec;
    $gps_lon = $gps_lon_deg . sprintf("%02d", $gps_lon_min) .  $gps_lon_min_dec;

#    $gps_lat = int($2) . $2 - int($2)) * 60;
#    $gps_lon = int($4) . $4 - int($4)) * 60;

   print $gps_lat_dir . $gps_lat . " " . $gps_lon_dir . $gps_lon . "\n";
  }
  if ($gps_okay = (($result = do_command($gpsd, "v")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,V=([\d\.]+)/; 
    $gps_speed = $1;
  }
  if ($gps_okay = (($result = do_command($gpsd, "t")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,T=([\d\.]+)/;
    $gps_heading = $1;
  }
  if ($gps_okay = (($result = do_command($gpsd, "a")) ? (1 && $gps_okay) : 0)) {
    $result =~ m/GPSD,A=([\d\.]+)/;
    $gps_alt = $1 * 3.28;
  }
# 
# ($inttemp, $outtemp) = get_temp($admon);
#  $inttemp = $inttemp ? $inttemp : "ERR";
#  $outtemp = $outtemp ? $outtemp : "ERR";
#  $tempstring = sprintf(" IT:%.3d OT:%.3d", $inttemp, $outtemp);
#  
  $aprs_string = sprintf("\=%.6dh%07.2f%s/%08.2f%s%s%.3d/%.3d/A=%.6d", $gps_utc, $gps_lat, $gps_lat_dir, $gps_lon, $gps_lon_dir, $map_char, $gps_heading, $gps_speed, $gps_alt);
#  $aprs_string = sprintf("\=%07.2f%s/%08.2f%s%s%.3d/%.3d/A=%.6d", $gps_lat, $gps_lat_dir, $gps_lon, $gps_lon_dir, $map_char, $gps_heading, $gps_speed, $gps_alt);
#  $aprs_string = $aprs_string.$tempstring;
  $aprs_string = $aprs_string." INVALID" unless $gps_valid;
  $aprs_string = $aprs_string." GPSERROR" unless $gps_okay;

  print $aprslog "$aprs_string\n";

  if ($beaconcounter >= $beaconmultiple) {
    $aprs_string = $aprs_string." Embedded Linux ".$email;
    system("beacon -d \"APRS VIA WIDE2-2\" -s $int \"$aprs_string\"");
    $beaconcounter = 1;
  }
  else {
    $beaconcounter++;
  }
  sleep $loginterval;
}                                 
