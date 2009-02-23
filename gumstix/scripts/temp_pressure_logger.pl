#!/usr/bin/perl

use warnings;
use IO::Socket;
use IO::Select;
use IO::File;

# configure port and speed to match the device
$LOGDIR		= "/var/log";
$LOGFILE	= "pt_data.log";
$INTERVAL	= 10;
$DEBUG		= 0;

# Arduino's host and port (using SerialDaemon)
$ARDHOST 	= "127.0.0.1";
$ARDPORT 	= "9600";

sub debug
{
  if($DEBUG) 
  {
    local($debugstr) = @_;
    print "DEBUG: " . $debugstr . "\n";
  }
}


sub ard_command {
  my (@ready, $s, $buf);
  my $handle = shift(@_);
  my $command = shift(@_);
  my $read_set = new IO::Select($handle);
  debug("Sending to socket: [$command]");
  print $handle "$command";
  while (1) {
    if (@ready = $read_set->can_read(2)) 
    {
      foreach $s (@ready) 
      {
	$buf = <$s>;
	if($buf)
	{
	  # The Arduino (through serialdaemon) seems to return an extra \r\n or so in between commands.
	  # Clean up the incoming buffer and if it's valid, return it. Otherwise, check the next packet.
	  chomp($buf);
	  $buf =~ s/\r$//;
          if($buf)
	  {
            debug("Got from socket: [$buf]");
	    return $buf;
	  }
	}
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
  if($result)
  {
    chomp($result);
    $result =~ s/\r$//;
    debug("Arduino returned: [". $result . "]");
    return $result;
  }
  else
  {
    print "ERROR: Arduino returned an invalid result\n";
    return;
  }
}

# open the log file
$logfile = new IO::File(">>$LOGDIR/$LOGFILE");
die "Could not open log file: $!\n" unless $logfile;
$logfile->autoflush(1);

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
 
  $time = `date "+%Y%m%d%H%M%S"`;
  chomp($time);
  $log = "$time $logstr\n";

  debug("LOG: $log");
  print $logfile $log;

  sleep $INTERVAL;
}
