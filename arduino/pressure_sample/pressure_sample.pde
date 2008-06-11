

int pressurePin = 0;

void setup(void) 
{
  // initialize inputs/outputs
  // start serial port
  Serial.begin(9600);
}

void loop(void) 
{
  int currentPressure = analogRead(pressurePin);
  
  Serial.print("Current pressure: ");
  Serial.print(currentPressure);
  Serial.println("/1023");
    
  delay(1000);
  
}
