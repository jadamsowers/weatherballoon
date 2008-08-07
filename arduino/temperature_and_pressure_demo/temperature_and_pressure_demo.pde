#include <OneWire.h>

// DS18S20 Temperature chip i/o

int pressurePin = 0;

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
   can push data[1] into an integer, shift it 8 bits, and add data[0]
   to get a 16-bit signed integer. Dividing by 2 will give us the 
   proper temperature reading with the extra .5C of resolution.
   */

  //debug code!
  /*
  data[0] = 255;
  data[1] = 255;
  */
  
  int tempRaw = (data[1] << 8) + data[0];

  float tempInC = tempRaw / 2.0; 
  float tempInF = tempInC * 1.8 + 32;

  int intTempInC = tempInC;
  int intTempInCrem = abs(tempInC - intTempInC) * 10;
  int intTempInF = tempInF;
  int intTempInFrem = abs(tempInF - intTempInF) * 10;

  Serial.print("temperature: ");
  if(tempInC < 0 && tempInC > -1)
  {
    //special case: -0.x
    Serial.print("-0");
  } 
  else  
  {
    Serial.print(intTempInC);
  }
  Serial.print(".");
  Serial.print(intTempInCrem);
  Serial.print("C, ");

  if(tempInF < 0 && tempInF > -1)
  {
    //special case: -0.x
    Serial.print("-0");
  } 
  else  
  {
    Serial.print(intTempInF);
  }
  Serial.print(".");
  Serial.print(intTempInFrem);
  Serial.println("F");

  /*  Serial.print(" CRC=");
   Serial.print( OneWire::crc8( data, 8), HEX);*/
  Serial.println();
  
  int currentPressRaw = analogRead(pressurePin);
  
  float currentPressure = (currentPressRaw * 0.0157) + 1.5555555;
  
  int intPressure = currentPressure;
  int intPressureRem = (currentPressure - intPressure) * 10;
  
  Serial.print("Current pressure: ");
  Serial.print(intPressure);
  Serial.print(".");
  Serial.println(intPressureRem);

}
