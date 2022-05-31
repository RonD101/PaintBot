import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
enum RobotMove { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoDown, goHome }
enum UploadFlag { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PulseStatus { nextPulse, reuploadPulse, finishedPulses }
enum MenuSelection { strokeWidth, brushColor, settingMenu, testMenu }
enum TestSelection { square, rightUpAllWay, goHome }
enum PointType { regular, dummyUp, dummyDown }

const Offset dummyOffset = Offset(-1, -1);
const Offset redOffset = Offset(50, 200);
const Offset waterOffset = Offset(50, 200);
const double a4Width = 3712.5;
const double a4Height = 2625;
const double mmToStep = 12.5; // motor steps per mm
const double distInCup = 50.0;
const int pulseCapacity = 500;
double navBarHeight = 0;
final DrawingPoint upPoint = DrawingPoint(location: dummyOffset, type: PointType.dummyUp, paint: Paint());
final DrawingPoint downPoint = DrawingPoint(location: dummyOffset, type: PointType.dummyDown, paint: Paint());

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
  final Offset location;
  final PointType type;
  const DrawingPoint({required this.location, required this.type, required this.paint});
  void printPoint() {
    debugPrint(location.dx.round().toString() + " " + location.dy.round().toString() + " " + type.toString());
  }
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter({required this.pointsList});
  final List<DrawingPoint> pointsList;
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      final Offset curLocation = pointsList[i].location;
      final Offset nextLocation = pointsList[i + 1].location;
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

class BotIcons {
  static const IconData undo = Icons.undo_outlined;
  static const IconData restart = Icons.restart_alt_outlined;
  static const IconData upload = Icons.upload_file_outlined;
  static const IconData square = Icons.crop_square_outlined;
  static const IconData rightUp = Icons.turn_right_sharp;
  static const IconData goHome = Icons.home_outlined;
  static const IconData stroke = Icons.line_weight;
  static const IconData color = Icons.color_lens_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData test = Icons.checklist_outlined;
}
