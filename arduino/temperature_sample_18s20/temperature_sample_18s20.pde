#include <OneWire.h>

// DS18S20 Temperature chip i/o

OneWire ds(10);  // on pin 10

void setup(void) {
  // initialize inputs/outputs
  // start serial port
  Serial.begin(9600);
}

void loop(void) {
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];

  if ( !ds.search(addr)) {
    //     Serial.print("No more addresses.\n");
    ds.reset_search();
    return;
  }

  Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[7 - i], HEX);
    Serial.print(" ");
  }
  Serial.println("");


  if ( OneWire::crc8( addr, 7) != addr[7]) {
    Serial.print("CRC is not valid!\n");
    return;
  }

  if ( addr[0] != 0x10) {
    Serial.print("Device is not a DS18S20 family device.\n");
    return;
  }

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end

  delay(1000);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.

  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  /* Serial.print("P=");
   Serial.print(present,HEX);
   Serial.print(" ");*/

  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    /*    Serial.print(data[i], HEX);
     Serial.print(" ");
     */
  }

  /*
    data[0] is the value in C. Because the resolution of the sensor
   is to .5C, the 2^-1 bit is stored in the LSB instead of the 2^0
   bit we're used to. Therefore we will have to divide by 2 and 
   store the result in a float to avoid losing resolution.
   
   data[1] is the sign byte. It will either be 00 or FF depending 
   on whether the temperature is positive or negative. Therefore we 
   can treat data[0] like an unsigned integer at first, and if 
   data[1] is FF, we know it's actually negative and convert as
   needed.
   */

  //debug code!
  data[0] = 206;
  data[1] = 255;

  int tempRaw = (data[1] << 8) + data[0];

  float tempInC = tempRaw / 2.0; 
  float tempInF = tempInC * 1.8 + 32;

  int intTempInC = tempInC;
  int intTempInCrem = (tempInC - intTempInC) * 10;
  int intTempInF = tempInF;
  int intTempInFrem = (tempInF - intTempInF) * 10;

  Serial.print("temperature: ");
  Serial.print(intTempInC);
  Serial.print(".");
  Serial.print(intTempInCrem);
  Serial.print("C, ");

  Serial.print(intTempInF);
  Serial.print(".");
  Serial.print(intTempInFrem);
  Serial.println("F");

  /*  Serial.print(" CRC=");
   Serial.print( OneWire::crc8( data, 8), HEX);*/
  Serial.println();
}
