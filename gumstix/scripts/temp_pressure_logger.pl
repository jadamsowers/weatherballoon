#!/usr/bin/perl
use warnings;

$DATE = `date "+%Y%m%d"`;
chomp($DATE);

# configure port and speed to match the device
$LOGDIR		= "/var/log";
$LOGFILE	= "pt_data_$DATE.log";
$PORT		= "/dev/arduino";
$BAUD		= "9600";
$INTERVAL	= 10;
$DEBUG		= 0;

sub debug
{
  if($DEBUG) 
  {
    local($debugstr) = @_;
    print "DEBUG: " . $debugstr . "\n";
  }
}

sub askForData 
{
  local($cmdstr) = @_;
  debug("sending the command \"${cmdstr}\" to Arduino");
  print DEV $cmdstr;
  $result = <DEV>;
  chomp($result);
  $result =~ s/\r$//;
  debug("Arduino returned: [". $result . "]");
  return $result;
}

# set up the serial port
debug("setting up serial port");
system("stty $BAUD raw < $PORT");


# open the log file
debug("opening log file $LOGDIR/$LOGFILE");
open(LOG, ">>${LOGDIR}/${LOGFILE}") || die "can't open file $LOGDIR/$LOGFILE for append";
select((select(LOG), $| = 1)[0]);


# open the port
debug("opening Arduino port: $PORT");
open(DEV, "+<$PORT") || die "can't open $PORT: $!";
#select((select(DEV), $| = 1)[0]);


# tell the Arduino to suppress status messages ('q') and return results in Celcius ('c')
#  human-readable ('h') results.
debug("sending initial commands to Arduino");
print DEV "qch";


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
