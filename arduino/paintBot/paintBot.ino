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

#include <ESP32Servo.h> 

Servo myservo;  // create servo object to control a servo

// Insert your network credentials
#define WIFI_SSID "TechPublic"
#define WIFI_PASSWORD ""
//#define WIFI_SSID "RK1996"
//#define WIFI_PASSWORD "dead4fun"

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

int servoPin = 12;

int homeLeftPin = 14;
int homeDownPin = 13;
void setup() {
  // Motot 1
  pinMode(motor1Dir, OUTPUT);    // Direction Pin
  pinMode(motor1Step, OUTPUT);    // Step pin
  pinMode(motor1Enable, OUTPUT);    // Enable pin
  // Motor 2
  pinMode(motor2Dir, OUTPUT);    // Direction Pin
  pinMode(motor2Step, OUTPUT);    // Step pin
  pinMode(motor2Enable, OUTPUT);    // Enable pin

  pinMode(homeLeftPin, INPUT);
  pinMode(homeDownPin, INPUT);

  digitalWrite(motor1Enable, LOW);
  digitalWrite(motor2Enable, LOW);
  digitalWrite(motor1Step, LOW);
  digitalWrite(motor2Step, LOW);

  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);// Standard 50hz servo
  myservo.attach(servoPin, 1000, 2000);
//
//  myservo.write(10);
  
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
  delay(2000);
}

int counter = 0;
int timeLap = 1000;
int HomeLeftState = 0;
int HomeDownState = 0;
bool initLeft = true;
bool initDown = true;
bool waitForRealseButton = false;
int flag;
int NumOfMoves;
int* movesArray;

void loop() {
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.getInt(&fbdo, "/Flag")) {
      WebSerial.print("Got flag = ");
      WebSerial.println(fbdo.intData());
      flag = fbdo.intData();
      if (flag == 0)
        return;
    } else {
      printDebugErrors();
    }
    if (flag == 4) {
        if (Firebase.RTDB.getInt(&fbdo, "/NumOfMoves")) {
        WebSerial.print("Got number of moves = ");
        WebSerial.println(fbdo.intData());
        Serial.print("Got number of moves = ");
        Serial.println(fbdo.intData());
        NumOfMoves = fbdo.intData();
        movesArray = new int[NumOfMoves];
        } else {
          printDebugErrors();
        }
    }
    if (flag == 2) {
      WebSerial.print("Amount of pulse got = ");
      WebSerial.println(counter);
      counter = 0;
      WebSerial.print("Start Draw ");
      WebSerial.print(NumOfMoves);
      WebSerial.println(" points!");
      for (int i = 0; i < NumOfMoves; i = i + 2) {
        int len = movesArray[i];
        int elem = movesArray[i + 1];
//        Firebase.RTDB.setInt(&fbdo, "/len", len);
//        Firebase.RTDB.setInt(&fbdo, "/elem", elem);
        Serial.print("i = ");
        Serial.println(i);
        Serial.print("NumOfMoves = ");
        Serial.println(NumOfMoves);
        Serial.print("len = ");
        Serial.println(len);
        Serial.print("elem = ");
        Serial.println(elem);
        for (int j = 0; j < len; j++) {
//        Firebase.RTDB.setInt(&fbdo, "/Debug 2", j);
          if (elem == 0)
              stepRight();
          else if (elem == 1)
              stepLeft();
          else if (elem == 2)
              stepUp();
          else if (elem == 3)
              stepDown();
          else if (elem == 4)
              stepRightUp();
          else if (elem == 5)
              stepRightDown();
          else if (elem == 6)
              stepLeftUp();
          else if (elem == 7)
              stepLeftDown();
          else if (elem == 8) {
              delay(300);
              myservo.write(10); // servo up
              delay(300);
          }
          else if (elem == 9) {
              delay(300);
              myservo.write(130); // servo down
              delay(300);
          }
          else if (elem == 10) {
              goHome();
          }
          else
              WebSerial.println("Error got unexpected robot move");
        }
      }
      Serial.println("End Draw!");
      WebSerial.println("End Draw!");
      delete[] movesArray;
    }
    if (flag == 1) {
      if (Firebase.RTDB.getArray(&fbdo, "/RobotMoves")) {
        Serial.println("Get array ok");
        FirebaseJsonArray arr = fbdo.jsonArray();
        FirebaseJsonData currValue;
        WebSerial.print("Array size: ");
        WebSerial.println(arr.size());
        arr.get(currValue, 0);
        int amountOfElemInArray = currValue.to<int>();
        if (amountOfElemInArray + 1 != arr.size()) {
          if (Firebase.RTDB.setInt(&fbdo, "/Flag", 3)){
            Serial.println("Set Flag to 3");
            WebSerial.println("Set Flag to 3 because of array sizes that doesn't match");
            WebSerial.print("first element: ");
            WebSerial.println(amountOfElemInArray);
            WebSerial.print("arr size: ");
            WebSerial.println(arr.size());
            return;
          }
          else {
            printDebugErrors();
          }
        } else {
          for (size_t i = 0; i < arr.size(); i++)
            {
              arr.get(currValue, i + 1);
              movesArray[1000 * counter + i] = currValue.to<int>();
            }
          
          WebSerial.println("Finished load!");
          counter += 1;
        }
      }
      else {
        printDebugErrors();
        if (Firebase.RTDB.setInt(&fbdo, "/Flag", 3)){
          Serial.println("Set Flag to 3");
          return;
        }
        else {
          printDebugErrors();
        }
      }
    }
   if (flag == -1) { // For debug
      if (Firebase.RTDB.setString(&fbdo, "/IP", WiFi.localIP().toString())){
        Serial.print("IP: ");
        Serial.println(WiFi.localIP());
      }
      else {
        printDebugErrors();
      }
   }
   if (Firebase.RTDB.setInt(&fbdo, "/Flag", 0)){
      Serial.println("Set Flag to zero");
    }
    else {
      printDebugErrors();
    }
  }
}

void printDebugErrors() {
  Serial.println("FAILED");
  Serial.println("REASON: " + fbdo.errorReason());
  WebSerial.println("FAILED");
  WebSerial.println("REASON: " + fbdo.errorReason());
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

void goHome() {
  WebSerial.println("Start go home");
  Serial.println("Start go home");
  HomeLeftState = digitalRead(homeLeftPin);
  HomeDownState = digitalRead(homeDownPin);
  while (HomeDownState == HIGH) {
    stepDown();
    HomeDownState = digitalRead(homeDownPin);
  }
  WebSerial.println("Finish go down");
  Serial.println("Finish go down");
  while (HomeLeftState == HIGH) {
    stepLeft();
    HomeLeftState = digitalRead(homeLeftPin);
  }
  WebSerial.println("Finish go Left");
  Serial.println("Finish go Left");
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
