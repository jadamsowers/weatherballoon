#include <SoftwareSerial.h>
#include <SSerial2Mobile.h>
#include <OneWire.h>


#define pressurePin 0
#define oneWirePin  10

#define phoneTX 7
#define phoneRX 6

char phoneNumber[ ] = "40404";

boolean rawOutput = true;
boolean verbose = false;

OneWire ds(oneWirePin); 
SSerial2Mobile phone = SSerial2Mobile(phoneRX, phoneTX);

// Change these values to reflect your own device IDs
byte insideTemp[8]  = { 0x10, 0x96, 0xC5, 0x81, 0x01, 0x08, 0x00, 0x83 };
byte outsideTemp[8] = { 0x10, 0xAA, 0xE6, 0x81, 0x01, 0x08, 0x00, 0xA5 };

byte data[12];
byte *addr = insideTemp; 


void printDouble( double val, byte precision)
{
  // http://forum.arduino.cc/index.php/topic,44216.0.html#13
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimial places
  // example: lcdPrintDouble( 3.1415, 2); // prints 3.14 (two decimal places)

  if (val < 0.0)
  {
    Serial.print('-');
    val = -val;
  }

  Serial.print (int(val));  //prints the int part
  if (precision > 0) 
  {
    Serial.print("."); // print the decimal point
    unsigned long frac;
    unsigned long mult = 1;
    byte padding = precision - 1;
    while(precision--) mult *= 10;

    if (val >= 0)
      frac = (val - int(val)) * mult;
    else
      frac = (int(val)- val) * mult;
    unsigned long frac1 = frac;
    while(frac1 /= 10) padding--;
    while(padding--) Serial.print("0");
    Serial.print(frac,DEC);
  }
}



/* 
Samples the pressure reading on the analog pin.
our PSI scale was determined empirically, so pass true to get the raw reading.
*/
   
void readPressure(boolean isRaw)
{
  int currentPressRaw = analogRead(pressurePin);
    
  Serial.print("P=");
  if(isRaw)
  {
    Serial.println(currentPressRaw);
  }
  else
  {
    float currentPressure = (currentPressRaw * 0.0157) + 1.5555555;
    Serial.println(printDouble(currentPressure, 2));
  }
}




// reads the temperature from the OneWire temperature sensor and outputs in deg. C
void readTemperature()
{
  byte i;
  byte present = 0;

  if ( OneWire::crc8( addr, 7) != addr[7]) 
  {
    Serial.print("CRC is not valid!\n");
    return;
  }

  if ( addr[0] != 0x10) 
  {
     Serial.print("Device is not a DS18S20 family device.\n");
     return;
  }

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion

  delay(100);  

  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);          // Read Scratchpad

  for ( i = 0; i < 9; i++) // we need 9 bytes
  { 
    data[i] = ds.read();
  }

  /*
  data[0] is the value in degrees C. Because the resolution of the sensor
  is to .5C, the 2^-1 bit is stored in the LSB instead of the 2^0
  bit we're used to. Therefore we will have to divide by 2 and 
  store the result in a float to avoid losing resolution.

  data[1] is the sign byte. It will either be 00 or FF depending 
  on whether the temperature is positive or negative. Therefore we 
  can push data[1] into an integer, shift it 8 bits, and add data[0]
  to get a 16-bit signed integer. Dividing by 2 will give us the 
  proper temperature reading with the extra .5C of resolution.
  */

  int tempRaw = (data[1] << 8) + data[0];

  Serial.print("T=");
  
  float temp = tempRaw / 2.0; 
    
  Serial.print(printDouble(temp, 1));
  Serial.println("C");

}


void sendSMSMessage(void)
{
  if(verbose) 
  {
    
    Serial.print("Phone status:   battery: ");
    Serial.print(phone.batt());
    Serial.print("%   Signal strength: ");
    Serial.println(phone.rssi());
    
  }
  
  // for now, disable sending text messages
  /*
  phone.sendTxt(phoneNumber, "Test message");
  */
}




void setup(void) 
{
  // initialize inputs/outputs
  // start serial and phone ports
  Serial.begin(9600); 
  phone.begin();
    
}





void loop(void) 
{
  
  char input;
  input = Serial.read();

  switch(tolower(input))
  {
    case 'i': // inside temperature
      addr = insideTemp;
      if(verbose) Serial.println("reading from inside temperature sensor");
      break;
    
    case 'o': // outside temperature
      addr = outsideTemp;
      if(verbose) Serial.println("reading from outside temperature sensor");
      break;  
      
    case 'h': // human-readable output
      rawOutput = false; 
      if(verbose) Serial.println("human-readable output enabled");
      break;
      
    case 'r': // raw output
      rawOutput = true;
      if(verbose) Serial.println("raw output enabled");
      break;
      
    case 'p': // pressure reading
      readPressure(rawOutput);
      break;
      
    case 't': // temperature reading
      readTemperature();
      break;      
    
    case 'q': // quiet output
      verbose = false;
      break; 
     
    case 'v': // verbose output
      verbose = true;
      Serial.println("Verbose output enabled"); 
      break;
      
    case 's': // SMS
      sendSMSMessage();
      break;
  }
}
