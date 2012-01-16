#!/usr/bin/perl

use warnings;
use IO::Socket;
use IO::Select;
use IO::File;

$DATE = `date "+%Y%m%d"`;
chomp($DATE);

# configure port and speed to match the device
$LOGDIR		= "/var/log";
$LOGFILE	= "pt_data_$DATE.log";
$PORT		= "/dev/arduino";
$BAUD		= "9600";
$INTERVAL	= 10;
$DEBUG		= 0;

# Arduino's host and port (using SerialDaemon)
$ARDHOST 	= "127.0.0.1";
$ARDPORT 	= "5000";

sub debug
{
  if($DEBUG) 
  {
    local($debugstr) = @_;
    print "DEBUG: " . $debugstr . "\n";
  }
}


sub ard_command {
  my @ready, $s, $buf;
  my $handle = shift(@_);
  my $command = shift(@_);
  my $read_set = new IO::Select($handle);
  print $handle "$command";
  while (1) {
    if (@ready = $read_set->can_read(2)) 
    {
      foreach $s (@ready) 
	  {
        return $buf;
      }
    }
    else 
    {
      return 0;
    }
  }        
}

# sends a command to the Arduino and returns the result
sub askForData 
{
  local($cmdstr) = @_;
  debug("sending the command \"${cmdstr}\" to Arduino");
  $result = ard_command($ard, $cmdstr);
  chomp($result);
  $result =~ s/\r$//;
  debug("Arduino returned: [". $result . "]");
  return $result;
}

# open the log file
$log = new IO::File(">>$LOGDIR/$LOGFILE");
die "Could not open log file: $!\n" unless $log;
$log->autoflush(1);

# open the Arduino socket
$opencount = 0;
while ((! $ard) && ($opencount < 30)) 
{
  $ard = new IO::Socket::INET
            (PeerAddr => $ARDHOST,
             PeerPort => $ARDPORT,
             Proto    => 'tcp',);
  $opencount++;
  sleep 1;
}
die "Could not create socket: $!\n" unless $ard;
$ard->autoflush(1);

# tell the Arduino to suppress status messages ('q') and return results in Celcius ('c')
#  human-readable ('h') results.
debug("sending initial commands to Arduino");
print $ard "qch";


while(1) 
{
  $logstr = "";

  # inside temperature
  $logstr .= " I" . askForData("it");

  # outside temperature                                                                  
  $logstr .= " O" . askForData("ot");

  # pressure
  $logstr .= " " . askForData("p");
 
  $log = time() . " $logstr\n";

  debug("LOG: $log");
  print LOG $log;

  sleep $INTERVAL;
}
