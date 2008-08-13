#include <OneWire.h>

// DS18S20 Temperature chip i/o

int pressurePin = 0;
int x;

boolean rawOutput = true;
boolean tempOutputC = true;

OneWire ds(10);  // on pin 10

byte insideTemp[8]  = { 0x10, 0x96, 0xC5, 0x81, 0x01, 0x08, 0x00, 0x83 };
byte outsideTemp[8] = { 0x10, 0xAA, 0xE6, 0x81, 0x01, 0x08, 0x00, 0xA5 };

byte data[12];
byte addr[8]; 

void setup(void) 
{
  // initialize inputs/outputs
  // start serial port
  Serial.begin(9600);

  for ( x = 0; x < 8; x++)
  {
    addr[x] = insideTemp[x];
  }
}

void loop(void) 
{
  byte i;
  byte present = 0;

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

  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
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
  
  int tempRaw = (data[1] << 8) + data[0];
  int currentPressRaw = analogRead(pressurePin);
  
  char input;
  input = Serial.read();

  switch(input)
  {
    case 'i': // inside temperature
      for ( x = 0; x < 8; x++)
      {
        addr[x] = insideTemp[x];       
      }
      Serial.println("reading from inside temperature sensor");
      break;
    
    case 'o': // outside temperature
      for ( x = 0; x < 8; x++)
      {
        addr[x] = outsideTemp[x];
      }
      Serial.println("reading from outside temperature sensor");
      break;  
      
    case 'h': // human-readable output
      rawOutput = false; 
      Serial.println("human-readable output enabled");
      break;
      
    case 'r': // raw output
      rawOutput = true;
      Serial.println("raw output enabled");
      break;
      
    case 'f': // Fahrenheit output
      tempOutputC = false;
      Serial.println("Temperature output will be given in degrees Fahrenheit");
      break;
      
    case 'c': // Celcius output
      tempOutputC = true;
      Serial.println("Temperature output will be given in degrees Celcius");
      break;
      
    case 'p': // pressure reading
      Serial.print("P=");
      if(rawOutput)
      {
        Serial.println(currentPressRaw);
      }
      else
      {
        float currentPressure = (currentPressRaw * 0.0157) + 1.5555555;
        int intPressure = currentPressure;
        int intPressureRem = (currentPressure - intPressure) * 10;
        Serial.print(intPressure);
        Serial.print(".");
        Serial.print(intPressureRem);
        Serial.println(" psi");
      }
      break;
      
    case 't': // temperature reading
      Serial.print("T=");
      if(rawOutput)
      {
        Serial.println(tempRaw);
      }
      else
      {
        float tempInC = tempRaw / 2.0; 
        if(tempOutputC)
        {
          int intTempInC = tempInC;
          int intTempInCrem = abs(tempInC - intTempInC) * 10;
        
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
          Serial.println("C");
        }
        else
        {
          float tempInF = tempInC * 1.8 + 32;

          int intTempInF = tempInF;
          int intTempInFrem = abs(tempInF - intTempInF) * 10;
          
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
        }
      }
      break;       
  }
}
