# PaintBot

This is a project done by Ron Dahan, Renen Kantor and Eyal Attiya with the supervision of Harel Vaknin and Tom Sofer as part of the IoT course at the Technion.

## Main features:
    - User paints on the app and the robot draws it on paper with water colors.
    - The user can choose from a variaty of colors and two differenet widths.
    - Restarting and reversing lines.
    - Built-in tests and calibration option.

## The core code for the app is in the lib folder containing the following files:
    - app_utils.dart: constants and define for the application - including distance from pallete, ticksPerCM etc.
    - bresenham_algo.dart: implementation of bresenham algorithm - contains the entire conversion from points on screen to composite moves.
    - brush_handler: implementation of colors, water and cleaner code.
    - main.dart: launcher for app.
    - robot_test.dart: following tests are provided - calibration, square, right up and go home feature.
    - upload_handler.dart: handles communication with firebase and arduino.

## Flow of application is as follows:
    - User paints on the app, and the app collects all the dots that are being painted.
    - User changes color/width as he wishes.
    - User select upload paint to firebase.
    - App takes the raw points from the user and performs the following chain of events
        - Scaling points according to paper and phone size.
        - Adds color, water and cleaner points.
        - Performing smoothing of points.
        - Invoking bresenham algorithm in points.
        - Converting bresenham points to robot moves.
        - Compressing robot moves.
    - Uploads compressed robot moves to firebase and performing "TCP" with robot until painting is fully uploaded.
        
Arduino code can be found in arduino/paintBot.ino - contains the entire code needed for the ESP32. Includes movements of steppers/servo, communication with firebase etc.
  - Flutter: 3.0.2
  - Dart: 2.17.3
  - DevTools: 2.12.2
  - firebase_core: 1.14.0
  - firebase_database: 9.0.10
  - <Arduino.h>
  - <WiFi.h>
  - <Firebase_ESP_Client.h>
  - <AsyncTCP.h>
  - <ESPAsyncWebServer.h>
  - <WebSerial.h>
  - <Vector.h>
  - "TokenHelper.h"
  - "RTDBHelper.h"
  - <ESP32Servo.h>

## List of items for the robot:
    - Two stepper motors
    - Two amplifiers for stepper motors
    - One Servo motor
    - Two touch sensors (for go home feature)
    - ESP32 
    - Voltage divider
    - Color pallete
    - Water cup
    - Water paint brush
    - Four metal bars
    - Four legs
    - Wooden frame
    - List of 3d-printed plastic items
    - Kappa base board
    - Paper clips and water color paper
  
    Link to firebase - https://console.firebase.google.com/u/0/project/paintbot-a1067/database/paintbot-a1067-default-rtdb/data
