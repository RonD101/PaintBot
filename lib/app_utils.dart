import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
enum MenuSelection { strokeWidth, brushColor, settingMenu }
enum UploadFlag { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PointType { regular, dummyUp, dummyDown }
enum RobotMove { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoDown }
enum PulseStatus { nextPulse, reuploadPulse, finishedPulses }

const double a4Width = 297;
const double a4Height = 210;
const double pixelToMM = 0.26458333;
const Offset dummyOffset = Offset(-1, -1);
const int pulseCapacity = 500;

class CompMove {
  final RobotMove move;
  int num;
  CompMove({required this.num, required this.move});
}

class DrawingPoint {
  final Paint paint;
  final Offset pointLocation;
  final PointType pointType;
  const DrawingPoint({required this.pointLocation, required this.paint, required this.pointType});
  void printPoint() {
    debugPrint(
        pointLocation.dx.round().toString() + " " + pointLocation.dy.round().toString() + " " + pointType.toString());
  }
}

final DatabaseReference movesRef = FirebaseDatabase.instance.ref("RobotMoves");
final DatabaseReference flagRef = FirebaseDatabase.instance.ref("Flag");
final DatabaseReference numOfMovesRef = FirebaseDatabase.instance.ref("NumOfMoves");
