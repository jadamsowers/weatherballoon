#!/usr/bin/perl

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://www.opengis.net/kml/2.2\"\n";
print "     xmlns:gx=\"http://www.google.com/kml/ext/2.2\">\n";
print "  <Placemark>\n";
print "    <name>APRS log</name>\n";
print "    <LineString>\n";
print "      <extrude>1</extrude>\n";
print "      <tessellate>1</tessellate>\n";
print "      <altitudeMode>absolute</altitudeMode>\n";
print "      <coordinates>\n";

@lines=(<>);
foreach (@lines)
{
  $line = $_;
  $line =~ m/^=\d+h(\d+.\d+)N\/(\d+.\d+)WO(\d+)\/(\d+)\/A=(\d+).*$/;
 
  $lat = $1;
  $lon = $2;
  $heading = $3;
  $speed = $4;
  $altitude = $5;

  $latint = int($lat / 100);
  $lat = ($lat - 100 * $latint) / 60 + $latint;

  $lonint = int($lon / 100);
  $lon = ($lon - 100 * $lonint) / 60 + $lonint;
  $lon *= -1;

  $altitude = int($altitude) * .3048;
  if($lon != 0) 
  {
    print "        $lon,$lat,$altitude\n";
  }

}
print "      </coordinates>\n";
print "    </LineString>\n";
print "  </Placemark>\n";
print "</kml>";
