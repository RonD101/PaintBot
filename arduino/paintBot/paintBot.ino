#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <WebSerial.h>
#include <Vector.h>

//Provide the token generation process info.
#include "addons/TokenHelper.h"
//Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Insert your network credentials
#define WIFI_SSID "TechPublic"
#define WIFI_PASSWORD ""

// Insert Firebase project API Key
#define API_KEY "AIzaSyAIVdnB_mJA6_ZV5G9ctjWO7aQRLJk_DjQ"

// Insert RTDB URLefine the RTDB URL */
#define DATABASE_URL "https://paintbot-a1067-default-rtdb.firebaseio.com/" 

AsyncWebServer server(80);

//Define Firebase Data object
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
int intValue;
float floatValue;
bool signupOK = false;

int motor1Enable = 2;
int motor1Step = 4;
int motor1Dir = 0;

int motor2Enable = 5;
int motor2Step = 19;
int motor2Dir = 18;

bool shouldStepMotor1 = false;
bool shouldStepMotor2 = false;
int led = 2;

int input = 13;
void setup() {
  // Motot 1
  pinMode(motor1Dir, OUTPUT);    // Direction Pin
  pinMode(motor1Step, OUTPUT);    // Step pin
  pinMode(motor1Enable, OUTPUT);    // Enable pin
  // Motor 2
  pinMode(motor2Dir, OUTPUT);    // Direction Pin
  pinMode(motor2Step, OUTPUT);    // Step pin
  pinMode(motor2Enable, OUTPUT);    // Enable pin

  pinMode(input, INPUT);

  digitalWrite(motor1Enable, LOW);
  digitalWrite(motor2Enable, LOW);
  digitalWrite(motor1Step, LOW);
  digitalWrite(motor2Step, LOW);
  
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  /* Assign the api key (required) */
  config.api_key = API_KEY;

  /* Assign the RTDB URL (required) */
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", "")){
    Serial.println("ok");
    signupOK = true;
  }
  else{
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback; //see addons/TokenHelper.h
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  
  WebSerial.begin(&server);
  server.begin();
  
  

  delay(10000);
}

int counter = 0;
int timeLap = 1000;
int buttonState = 0;
bool initLeft = true;
bool initDown = true;
bool waitForRealseButton = false;
Vector<int> vec;

void loop() {
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.getInt(&fbdo, "/Flag")) {
      WebSerial.print("Got flag = ");
      WebSerial.println(fbdo.intData());
      if (fbdo.intData() == 0)
        return;
    } else {
      Serial.println(fbdo.errorReason());
      WebSerial.println(fbdo.errorReason());
    }
    if (fbdo.intData() == 2) {
      for (int elem : vec) {
        if (elem == 0)
          stepRight();
        if (elem == 1)
            stepLeft();
        if (elem == 2)
            stepUp();
        if (elem == 3)
            stepDown();
        if (elem == 4)
            stepRightUp();
        if (elem == 5)
            stepRightDown();
        if (elem == 6)
            stepLeftUp();
        if (elem == 7)
            stepLeftDown();        
      }
      vec = Vector<int>();
    }
    if (fbdo.intData() == 2) {
      if (Firebase.RTDB.getArray(&fbdo, "/RobotMoves")) {
        
        Serial.println("Get array ok");
       
        FirebaseJsonArray arr = fbdo.jsonArray();
        FirebaseJsonData currValue;
        WebSerial.print("Array size: ");
        WebSerial.println(arr.size());
        WebSerial.println("Start Draw!");
        for (size_t i = 0; i < arr.size(); i++)
          {
            arr.get(currValue, i);
            vec.push_back(currValue.to<int>());
          }
        
        WebSerial.println("End Draw!");
      }
      else {
        Serial.println(fbdo.errorReason());
        WebSerial.println(fbdo.errorReason());
      }
    }
   if (Firebase.RTDB.setInt(&fbdo, "/Flag", 0)){
      Serial.println("Set Flag to zero");
    }
    else {
      Serial.println("FAILED");
      Serial.println("REASON: " + fbdo.errorReason());
      WebSerial.println("FAILED");
      WebSerial.println("REASON: " + fbdo.errorReason());
    }
  }
}


void mainLoop() {
   if (counter < timeLap)
    stepRight();
   if (counter > timeLap && counter < 2 * timeLap)
    stepLeft();
   if (counter > 2 * timeLap && counter <  3 * timeLap)
    stepUp();
   if (counter > 3 * timeLap && counter < 4 * timeLap)
    stepDown();
   if (counter > 4 * timeLap && counter < 5 * timeLap)
    stepRightUp();
   if (counter > 5 * timeLap && counter < 6 * timeLap)
    stepLeftDown();
   if (counter > 6 * timeLap && counter <  7 * timeLap)
    stepUp();
   if (counter > 7 * timeLap && counter < 8 * timeLap)
    stepRightDown();
   if (counter > 8 * timeLap && counter < 9 * timeLap)
    stepLeftUp();
   if (counter > 9 * timeLap && counter <  10 * timeLap)
    stepDown();
   if (counter > 10 * timeLap)
    counter = 0;
   if (counter % timeLap == 0)
    delay(500);
   counter++;
   delay(1);
}

void initMotors() {
  buttonState = digitalRead(input);
  if (buttonState == LOW && not waitForRealseButton) {
      if (initLeft) {
        initLeft = false;
        waitForRealseButton = true;
      }
      else if(initDown) {
        initDown = false;
        waitForRealseButton = true;
      }
   }
  if (not waitForRealseButton) {
    if (initLeft)
      stepLeft();
    else if(initDown)
      stepDown();
  } else if (buttonState == HIGH)
      waitForRealseButton = false;
  delay(1);
}

void stepMotors() {
  if (shouldStepMotor1) {
    digitalWrite(motor1Step, HIGH);
  }
  if (shouldStepMotor2) {
    digitalWrite(motor2Step, HIGH);
  }
  if (shouldStepMotor1) {
    digitalWrite(motor1Step, LOW);
  }
  if (shouldStepMotor2) {
    digitalWrite(motor2Step, LOW);
  }
  delay(1);
}

void stepLeftUp() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, HIGH);
  shouldStepMotor1 = true;
  shouldStepMotor2 = false;
  digitalWrite(motor1Dir, LOW);
  stepMotors();
}

void stepRightDown() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, HIGH);
  shouldStepMotor1 = true;
  shouldStepMotor2 = false;
  digitalWrite(motor1Dir, HIGH);
  stepMotors();
}

void stepRightUp() {
//  digitalWrite(motor1Enable, HIGH);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = false;
  shouldStepMotor2 = true;
  digitalWrite(motor2Dir, HIGH);
  stepMotors();
}

void stepLeftDown() {
//  digitalWrite(motor1Enable, HIGH);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = false;
  shouldStepMotor2 = true;
  digitalWrite(motor2Dir, LOW);
  stepMotors();
}

void stepLeft() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(motor1Dir, LOW);
  digitalWrite(motor2Dir, LOW);
  stepMotors();
}

void stepRight() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(motor1Dir, HIGH);
  digitalWrite(motor2Dir, HIGH);
  stepMotors();
}

void stepUp() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(motor1Dir, LOW);
  digitalWrite(motor2Dir, HIGH);
  stepMotors();
}

void stepDown() {
//  digitalWrite(motor1Enable, LOW);
//  digitalWrite(motor2Enable, LOW);
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(motor1Dir, HIGH);
  digitalWrite(motor2Dir, LOW);
  stepMotors();
}
