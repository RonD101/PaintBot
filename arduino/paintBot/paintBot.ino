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
#define WIFI_SSID "TechPublic"
#define WIFI_PASSWORD ""
// #define WIFI_SSID "RonDiPhone"
// #define WIFI_PASSWORD "12345678"
#define API_KEY "AIzaSyAIVdnB_mJA6_ZV5G9ctjWO7aQRLJk_DjQ"
// Insert RTDB URLefine the RTDB URL */
#define DATABASE_URL "https://paintbot-a1067-default-rtdb.firebaseio.com/"
#define LEFT_MOTOR_EN_PIN 2
#define LEFT_MOTOR_STEP_PIN 4
#define LEFT_MOTOR_DIR_PIN 0
#define RIGHT_MOTOR_EN_PIN 5
#define RIGHT_MOTOR_STEP_PIN 19
#define RIGHT_MOTOR_DIR_PIN 18
#define SERVO_PIN 12
#define HOME_LEFT_PIN 14
#define HOME_DOWN_PIN 13
//This define is for web serial debuging
//#define WEB_DEBUG

#ifdef WEB_DEBUG
AsyncWebServer server(80);
#endif

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
Servo upDownServo;

unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
bool shouldStepLeftMotor = false;
bool shouldStepRightMotor = false;
// This bools should only be true if we chose different configuration for the motors
bool shouldSwitchLeftMotorDir = false;
bool shouldSwitchRightMotorDir = false;

void setup() {
  // Left motor
  pinMode(LEFT_MOTOR_DIR_PIN, OUTPUT);  // Direction Pin
  pinMode(LEFT_MOTOR_STEP_PIN, OUTPUT); // Step pin
  pinMode(LEFT_MOTOR_EN_PIN, OUTPUT);   // Enable pin
  // Right motor
  pinMode(RIGHT_MOTOR_DIR_PIN, OUTPUT);  // Direction Pin
  pinMode(RIGHT_MOTOR_STEP_PIN, OUTPUT); // Step pin
  pinMode(RIGHT_MOTOR_EN_PIN, OUTPUT);   // Enable pin
  // Go home sensors
  pinMode(HOME_LEFT_PIN, INPUT);
  pinMode(HOME_DOWN_PIN, INPUT);

  digitalWrite(LEFT_MOTOR_EN_PIN, LOW);
  digitalWrite(RIGHT_MOTOR_EN_PIN, LOW);
  digitalWrite(LEFT_MOTOR_STEP_PIN, LOW);
  digitalWrite(RIGHT_MOTOR_STEP_PIN, LOW);

  ESP32PWM::allocateTimer(0);
  upDownServo.setPeriodHertz(50);// Standard 50hz servo
  upDownServo.attach(SERVO_PIN, 1000, 2000);

  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("ok");
    signupOK = true;
  }
  else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  // Assign the callback function for the long running token generation task
  config.token_status_callback = tokenStatusCallback; //see addons/TokenHelper.h

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  #ifdef WEB_DEBUG
    WebSerial.begin(&server);
    server.begin();
  #endif
  delay(500);
}

int amountOfDataPackages = 0;
int numOfMoves;
int* movesArray;
int pageWidth = 0;
int pageHight = 0;

void loop() {
  int flag;
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
        if (Firebase.RTDB.getInt(&fbdo, "/numOfMoves")) {
        debugPrint("Got number of moves = ");
        debugPrintln(fbdo.intData());
        Serial.print("Got number of moves = ");
        Serial.println(fbdo.intData());
        numOfMoves = fbdo.intData();
        movesArray = new int[numOfMoves];
        } else {
          printDebugErrors();
        }
    }
    if (flag == 2) {
      debugPrint("Amount of pulse got = ");
      debugPrintln(amountOfDataPackages);
      amountOfDataPackages = 0;
      debugPrint("Start Draw ");
      debugPrint(numOfMoves);
      debugPrintln(" points!");
      for (int i = 0; i < numOfMoves; i = i + 2) {
        int len = movesArray[i];
        int elem = movesArray[i + 1];
        Serial.print("i = ");
        Serial.println(i);
        Serial.print("numOfMoves = ");
        Serial.println(numOfMoves);
        Serial.print("len = ");
        Serial.println(len);
        Serial.print("elem = ");
        Serial.println(elem);
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
              upDownServo.write(10); // servo up
              delay(300);
          }
          else if (elem == 9) {
              delay(300);
              upDownServo.write(130); // servo down
              delay(300);
          }
          else if (elem == 10) {
              goHome();
              Firebase.RTDB.setInt(&fbdo, "/width", pageWidth);
              Firebase.RTDB.setInt(&fbdo, "/hight", pageHight);
          }
          else
              debugPrintln("Error got unexpected robot move");
        }
      }
      Serial.println("End Draw!");
      debugPrintln("End Draw!");
      delete[] movesArray;
    }
    if (flag == 1) {
      if (Firebase.RTDB.getArray(&fbdo, "/RobotMoves")) {
        Serial.println("Get array ok");
        FirebaseJsonArray arr = fbdo.jsonArray();
        FirebaseJsonData currValue;
        debugPrint("Array size: ");
        debugPrintln(arr.size());
        arr.get(currValue, 0);
        int amountOfElemInArray = currValue.to<int>();
        if (amountOfElemInArray + 1 != arr.size()) {
          if (Firebase.RTDB.setInt(&fbdo, "/Flag", 3)){
            Serial.println("Set Flag to 3");
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
              movesArray[1000 * amountOfDataPackages + i] = currValue.to<int>();
            }

          debugPrintln("Finished load!");
          amountOfDataPackages += 1;
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
  debugPrintln("FAILED");
  debugPrint("REASON: ");
  debugPrintln(fbdo.errorReason());
}

void testRobotMovement() {
  int timeLap = 1000;
  for (int cnt = 0; cnt < 10 * timeLap; cnt++) {
    if (cnt < timeLap)
      stepRight();
    if (cnt > timeLap && cnt < 2 * timeLap)
      stepLeft();
    if (cnt > 2 * timeLap && cnt <  3 * timeLap)
      stepUp();
    if (cnt > 3 * timeLap && cnt < 4 * timeLap)
      stepDown();
    if (cnt > 4 * timeLap && cnt < 5 * timeLap)
      stepRightUp();
    if (cnt > 5 * timeLap && cnt < 6 * timeLap)
      stepLeftDown();
    if (cnt > 6 * timeLap && cnt <  7 * timeLap)
      stepUp();
    if (cnt > 7 * timeLap && cnt < 8 * timeLap)
      stepRightDown();
    if (cnt > 8 * timeLap && cnt < 9 * timeLap)
      stepLeftUp();
    if (cnt > 9 * timeLap && cnt <  10 * timeLap)
      stepDown();
  }
}

void goHome() {
  pageWidth = 0;
  pageHight = 0;
  debugPrintln("Start go home");
  Serial.println("Start go home");
  int homeLeftState = digitalRead(HOME_LEFT_PIN);
  int homeDownState = digitalRead(HOME_DOWN_PIN);
  while (homeDownState == HIGH) {
    stepDown();
    pageHight += 1;
    homeDownState = digitalRead(HOME_DOWN_PIN);
  }
  debugPrintln("Finish go down");
  Serial.println("Finish go down");
  while (homeLeftState == HIGH) {
    stepLeft();
    pageWidth+= 1;
    homeLeftState = digitalRead(HOME_LEFT_PIN);
  }
  debugPrintln("Finish go Left");
  Serial.println("Finish go Left");
  debugPrint("X counter = ");
  debugPrintln(pageWidth);
  debugPrint("Y counter = ");
  debugPrintln(pageHight);
}

void stepMotors() {
  if (shouldStepLeftMotor) {
    digitalWrite(LEFT_MOTOR_STEP_PIN, HIGH);
  }
  if (shouldStepRightMotor) {
    digitalWrite(RIGHT_MOTOR_STEP_PIN, HIGH);
  }
  if (shouldStepLeftMotor) {
    digitalWrite(LEFT_MOTOR_STEP_PIN, LOW);
  }
  if (shouldStepRightMotor) {
    digitalWrite(RIGHT_MOTOR_STEP_PIN, LOW);
  }
  delay(1);
}

void stepLeftUp() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = false;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepRightDown() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = false;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepRightUp() {
  shouldStepLeftMotor = false;
  shouldStepRightMotor = true;
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepLeftDown() {
  shouldStepLeftMotor = false;
  shouldStepRightMotor = true;
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepLeft() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

void stepRight() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepUp() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? HIGH : LOW);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? LOW : HIGH);
  stepMotors();
}

void stepDown() {
  shouldStepLeftMotor = true;
  shouldStepRightMotor = true;
  digitalWrite(LEFT_MOTOR_DIR_PIN, shouldSwitchLeftMotorDir ? LOW : HIGH);
  digitalWrite(RIGHT_MOTOR_DIR_PIN, shouldSwitchRightMotorDir ? HIGH : LOW);
  stepMotors();
}

void debugPrint(char* str) {
  #ifdef WEB_DEBUG
    WebSerial.print(str);
  #endif
}

void debugPrintln(char* str) {
  #ifdef WEB_DEBUG
    WebSerial.println(str);
  #endif
}

void debugPrint(int str) {
  #ifdef WEB_DEBUG
    WebSerial.print(str);
  #endif
}

void debugPrintln(int str) {
  #ifdef WEB_DEBUG
    WebSerial.println(str);
  #endif
}

void debugPrint(String str) {
  #ifdef WEB_DEBUG
    WebSerial.print(str);
  #endif
}

void debugPrintln(String str) {
  #ifdef WEB_DEBUG
    WebSerial.println(str);
  #endif
}
