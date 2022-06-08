#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <WebSerial.h>
#include <Vector.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <ESP32Servo.h>


// Insert your network credentials
//#define WIFI_SSID "TechPublic"
//#define WIFI_PASSWORD ""
#define WIFI_SSID "RonDiPhone"
#define WIFI_PASSWORD "12345678"

// Insert Firebase project API Key
#define API_KEY "AIzaSyAIVdnB_mJA6_ZV5G9ctjWO7aQRLJk_DjQ"
// Insert RTDB URLefine the RTDB URL */
#define DATABASE_URL "https://paintbot-a1067-default-rtdb.firebaseio.com/"

//#define WEB_DEBUG
#define SERIAL_DEBUG

#define LEFT_MOTOR_ENABLE_PIN 2
#define LEFT_MOTOR_STEP_PIN 4
#define LEFT_MOTOR_DIR_PIN 0

#define RIGHT_MOTOR_ENABLE_PIN 5
#define RIGHT_MOTOR_STEP_PIN 19
#define RIGHT_MOTOR_DIR_PIN 18

#define SERVO_PIN 33

#define LEFT_SENSOR_PIN 14
#define DOWN_SENSOR_PIN 27

#ifdef WEB_DEBUG
  AsyncWebServer server(80);
#endif

Servo myservo;  // create servo object to control a servo

//Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
int intValue;
float floatValue;
bool signupOK = false;

// This bools should only be true if we chose different configuration for the motors
// (like if the motor is upsidedown)
bool shouldSwitchLeftMotorDir = true;
bool shouldSwitchRightMotorDir = false;

bool shouldStepMotor1 = false;
bool shouldStepMotor2 = false;

int counter = 0;
int HomeLeftState = 0;
int HomeDownState = 0;
bool initLeft = true;
bool initDown = true;
bool waitForRealseButton = false;
int flag;
int NumOfMoves;
int* movesArray;

void setup() {
  // Motot 1
  pinMode(LEFT_MOTOR_DIR_PIN, OUTPUT);    // Direction Pin
  pinMode(LEFT_MOTOR_STEP_PIN, OUTPUT);    // Step pin
  pinMode(LEFT_MOTOR_ENABLE_PIN, OUTPUT);    // Enable pin
  // Motor 2
  pinMode(RIGHT_MOTOR_DIR_PIN, OUTPUT);    // Direction Pin
  pinMode(RIGHT_MOTOR_STEP_PIN, OUTPUT);    // Step pin
  pinMode(RIGHT_MOTOR_ENABLE_PIN, OUTPUT);    // Enable pin

  pinMode(LEFT_SENSOR_PIN, INPUT);
  pinMode(DOWN_SENSOR_PIN, INPUT);

  digitalWrite(LEFT_MOTOR_ENABLE_PIN, LOW);
  digitalWrite(RIGHT_MOTOR_ENABLE_PIN, LOW);
  digitalWrite(LEFT_MOTOR_STEP_PIN, LOW);
  digitalWrite(RIGHT_MOTOR_STEP_PIN, LOW);

  ESP32PWM::allocateTimer(0);
  myservo.setPeriodHertz(50);// Standard 50hz servo
  myservo.attach(SERVO_PIN, 1000, 2000);

  #ifdef SERIAL_DEBUG
    Serial.begin(115200);
  #endif
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  debugPrint("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED){
    debugPrint(".");
    delay(300);
  }
  debugPrintln("");
  debugPrint("Connected with IP: ");
  debugPrintln(WiFi.localIP());

  /* Assign the api key (required) */
  config.api_key = API_KEY;

  /* Assign the RTDB URL (required) */
  config.database_url = DATABASE_URL;

  /* Sign up */
  if (Firebase.signUp(&config, &auth, "", "")){
    debugPrintln("ok");
    signupOK = true;
  }
  else{
    debugPrintln(config.signer.signupError.message.c_str());
  }

  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback; //see addons/TokenHelper.h

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
   #ifdef WEB_DEBUG
     WebSerial.begin(&server);
     server.begin();
   #endif
  delay(2000);
}

void loop() {
  if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 3000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.getInt(&fbdo, "/Flag")) {
      debugPrint("Got flag = ");
      debugPrintln(fbdo.intData());
      flag = fbdo.intData();
      if (flag == 0)
        return;
    } else {
      printDebugErrors();
    }
    if (flag == 4) {
        if (Firebase.RTDB.getInt(&fbdo, "/NumOfMoves")) {
        debugPrint("Got number of moves = ");
        debugPrintln(fbdo.intData());
        NumOfMoves = fbdo.intData();
        movesArray = new int[NumOfMoves];
        } else {
          printDebugErrors();
        }
    }
    if (flag == 2) {
      debugPrint("Amount of pulse got = ");
      debugPrintln(counter);
      counter = 0;
      debugPrint("Start Draw ");
      debugPrint(NumOfMoves);
      debugPrintln(" points!");
      for (int i = 0; i < NumOfMoves; i = i + 2) {
        int len = movesArray[i];
        int elem = movesArray[i + 1];
        debugPrint("i = ");
        debugPrintln(i);
        debugPrint("NumOfMoves = ");
        debugPrintln(NumOfMoves);
        debugPrint("len = ");
        debugPrintln(len);
        debugPrint("elem = ");
        debugPrintln(elem);
        for (int j = 0; j < len; j++) {
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
              myservo.write(180); // servo up
              delay(300);
          }
          else if (elem == 9) {
              delay(300);
              myservo.write(50); // servo down
              delay(300);
          }
          else if (elem == 10) {
              goHome();
          }
          else
              debugPrintln("Error got unexpected robot move");
        }
      }
      debugPrintln("End Draw!");
      delete[] movesArray;
    }
    if (flag == 1) {
      if (Firebase.RTDB.getArray(&fbdo, "/RobotMoves")) {
        debugPrintln("Get array ok");
        FirebaseJsonArray arr = fbdo.jsonArray();
        FirebaseJsonData currValue;
        debugPrint("Array size: ");
        debugPrintln(arr.size());
        arr.get(currValue, 0);
        int amountOfElemInArray = currValue.to<int>();
        if (amountOfElemInArray + 1 != arr.size()) {
          if (Firebase.RTDB.setInt(&fbdo, "/Flag", 3)){
            debugPrintln("Set Flag to 3 because of array sizes that doesn't match");
            debugPrint("first element: ");
            debugPrintln(amountOfElemInArray);
            debugPrint("arr size: ");
            debugPrintln(arr.size());
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
          debugPrintln("Finished load!");
          counter += 1;
        }
      }
      else {
        printDebugErrors();
        if (Firebase.RTDB.setInt(&fbdo, "/Flag", 3)){
          debugPrintln("Set Flag to 3");
          return;
        }
        else {
          printDebugErrors();
        }
      }
    }
   if (flag == -1) { // For debug
      if (Firebase.RTDB.setString(&fbdo, "/IP", WiFi.localIP().toString())){
        debugPrint("IP: ");
        debugPrintln(WiFi.localIP());
      }
      else {
        printDebugErrors();
      }
   }
   if (Firebase.RTDB.setInt(&fbdo, "/Flag", 0)){
      debugPrintln("Set Flag to zero");
    }
    else {
      printDebugErrors();
    }
  }
}

void printDebugErrors() {
  debugPrintln("FAILED");
  debugPrintln("REASON: " + fbdo.errorReason());
}

void mainLoop() {
  int timeLap = 1000;
  for(int i = 0; i < 10 * timeLap; i++) {
    if (i < timeLap)
    stepRight();
    if (i > timeLap && i < 2 * timeLap)
    stepLeft();
    if (i > 2 * timeLap && i <  3 * timeLap)
    stepUp();
    if (i > 3 * timeLap && i < 4 * timeLap)
    stepDown();
    if (i > 4 * timeLap && i < 5 * timeLap)
    stepRightUp();
    if (i > 5 * timeLap && i < 6 * timeLap)
    stepLeftDown();
    if (i > 6 * timeLap && i <  7 * timeLap)
    stepUp();
    if (i > 7 * timeLap && i < 8 * timeLap)
    stepRightDown();
    if (i > 8 * timeLap && i < 9 * timeLap)
    stepLeftUp();
    if (i > 9 * timeLap && i <  10 * timeLap)
    stepDown();
  }
}

void goHome() {
  debugPrintln("Start go home");
  HomeLeftState = digitalRead(LEFT_SENSOR_PIN);
  HomeDownState = digitalRead(DOWN_SENSOR_PIN);
  while (HomeDownState == HIGH) {
    stepDown();
    HomeDownState = digitalRead(DOWN_SENSOR_PIN);
  }
  debugPrintln("Finish go down");
  while (HomeLeftState == HIGH) {
    stepLeft();
    HomeLeftState = digitalRead(LEFT_SENSOR_PIN);
  }
  debugPrintln("Finish go Left");
}

void stepMotors() {
  if (shouldStepMotor1) {
    digitalWrite(LEFT_MOTOR_STEP_PIN, HIGH);
  }
  if (shouldStepMotor2) {
    digitalWrite(RIGHT_MOTOR_STEP_PIN, HIGH);
  }
  if (shouldStepMotor1) {
    digitalWrite(LEFT_MOTOR_STEP_PIN, LOW);
  }
  if (shouldStepMotor2) {
    digitalWrite(RIGHT_MOTOR_STEP_PIN, LOW);
  }
  delay(1);
}

void stepLeftDown() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = false;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepRightUp() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = false;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepRightDown() {
  shouldStepMotor1 = false;
  shouldStepMotor2 = true;
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepLeftUp() {
  shouldStepMotor1 = false;
  shouldStepMotor2 = true;
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepLeft() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepRight() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepDown() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepUp() {
  shouldStepMotor1 = true;
  shouldStepMotor2 = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

 void debugPrint(char* str) {
   #ifdef SERIAL_DEBUG
     Serial.print(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.print(str);
   #endif
 }

 void debugPrintln(char* str) {
   #ifdef SERIAL_DEBUG
     Serial.println(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.println(str);
   #endif
 }

 void debugPrint(int str) {
   #ifdef SERIAL_DEBUG
     Serial.print(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.print(str);
   #endif
 }

 void debugPrintln(int str) {
   #ifdef SERIAL_DEBUG
     Serial.println(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.println(str);
   #endif
 }

 void debugPrint(String str) {
   #ifdef SERIAL_DEBUG
     Serial.print(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.print(str);
   #endif
 }

 void debugPrintln(String str) {
   #ifdef SERIAL_DEBUG
     Serial.println(str);
   #endif
   #ifdef WEB_DEBUG
     WebSerial.println(str);
   #endif
 }
