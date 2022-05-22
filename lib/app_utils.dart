import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
enum RobotMove { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoDown, goHome }
enum UploadFlag { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PulseStatus { nextPulse, reuploadPulse, finishedPulses }
enum MenuSelection { strokeWidth, brushColor, settingMenu }
enum PointType { regular, dummyUp, dummyDown }

const Offset dummyOffset = Offset(-1, -1);
const double a4Width = 297;
const double a4Height = 210;
const double pixelToMM = 0.26458333; // mms per pixel
const double mmToStep = 12.5; // motor steps per mm
const int pulseCapacity = 500;

final DatabaseReference numOfMovesRef = FirebaseDatabase.instance.ref("NumOfMoves");
final DatabaseReference movesRef = FirebaseDatabase.instance.ref("RobotMoves");
final DatabaseReference flagRef = FirebaseDatabase.instance.ref("Flag");

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

class DrawingPainter extends CustomPainter {
  const DrawingPainter({required this.pointsList});
  final List<DrawingPoint> pointsList;
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      final Offset curLocation = pointsList[i].pointLocation;
      final Offset nextLocation = pointsList[i + 1].pointLocation;
      if (curLocation != dummyOffset && nextLocation != dummyOffset) {
        canvas.drawLine(curLocation, nextLocation, pointsList[i].paint);
      } else if (curLocation != dummyOffset && nextLocation == dummyOffset) {
        canvas.drawPoints(
            PointMode.points, [curLocation, Offset(curLocation.dx + 0.1, curLocation.dy + 0.1)], pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
