import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
enum RobotMove     { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoDown, goHome }
enum UploadFlag    { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PulseStatus   { nextPulse, reuploadPulse, finishedPulses }
enum MenuSelection { strokeWidth, brushColor, settingMenu, testMenu }
enum TestSelection { square, rightUpAllWay, goHome }
enum PointType     { regular, dummyUp, dummyDown }

const int pulseCapacity  = 500;
const double opacity     = 1.0;
const double cupSize     = 300;
const double colorXBase  = 10;
const double colorYBase  = -10;
const double a4Width     = 3712.5;
const double a4Hight     = 2625;
const double mmToStep    = 12.5;
const double distInCup   = cupSize / 3;
const double xOffset     = 0;
const double yOffset     = 0;

const Offset dummyOffset = Offset(-1, -1);
const Offset waterOffset = Offset(0 * cupSize + cupSize / 2 + colorXBase, a4Hight + colorYBase);
const Offset redOffset   = Offset(1 * cupSize + cupSize / 2 + colorXBase, a4Hight + colorYBase);
const Offset greenOffset = Offset(2 * cupSize + cupSize / 2 + colorXBase, a4Hight + colorYBase);
const Offset blueOffset  = Offset(3 * cupSize + cupSize / 2 + colorXBase, a4Hight + colorYBase);

final DrawingPoint upPoint    = DrawingPoint(location: dummyOffset, type: PointType.dummyUp, paint: Paint());
final DrawingPoint downPoint  = DrawingPoint(location: dummyOffset, type: PointType.dummyDown, paint: Paint());
final DrawingPoint startPoint = DrawingPoint(location: const Offset(0, a4Hight), type: PointType.regular, paint: Paint());

final DatabaseReference numOfMovesRef = FirebaseDatabase.instance.ref("NumOfMoves");
final DatabaseReference movesRef      = FirebaseDatabase.instance.ref("RobotMoves");
final DatabaseReference flagRef       = FirebaseDatabase.instance.ref("Flag");

class CompMove {
  final RobotMove move;
  int num;
  CompMove({required this.num, required this.move});
  void printComp() {
    debugPrint(num.toString() + " " + move.name);
  }
}

class DrawingPoint {
  final PointType type;
  final Offset    location;
  final Paint     paint;
  const DrawingPoint({required this.location, required this.type, required this.paint});
  void printPoint() {
    debugPrint(location.dx.round().toString() + " " + location.dy.round().toString() + " " + type.toString());
  }
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter({required this.pointList});
  final List<DrawingPoint> pointList;
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointList.length - 1; i++) {
      final Offset curLoc = pointList[i].location;
      final Offset nexLoc = pointList[i + 1].location;
      if (curLoc != dummyOffset && nexLoc != dummyOffset) {
        canvas.drawLine(curLoc, nexLoc, pointList[i].paint);
      } else if (curLoc != dummyOffset && nexLoc == dummyOffset) {
        canvas.drawPoints(
            PointMode.points, [curLoc, Offset(curLoc.dx + 0.1, curLoc.dy + 0.1)], pointList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class BotIcons {
  static const IconData undo     = Icons.undo_outlined;
  static const IconData restart  = Icons.restart_alt_outlined;
  static const IconData upload   = Icons.upload_file_outlined;
  static const IconData square   = Icons.crop_square_outlined;
  static const IconData rightUp  = Icons.turn_right_sharp;
  static const IconData goHome   = Icons.home_outlined;
  static const IconData stroke   = Icons.line_weight;
  static const IconData color    = Icons.color_lens_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData test     = Icons.checklist_outlined;
}
