import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// 10cm/1000 = 10 * 10^-5 meters/tick left/right/up/down.
enum RobotMove     { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoDown, goHome }
enum UploadFlag    { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PulseStatus   { nextPulse, reuploadPulse, finishedPulses }
enum MenuSelection { strokeWidth, brushColor, settingMenu, testMenu }
enum TestSelection { square, rightUpAllWay, goHome }
enum PointType     { regular, dummyUp, dummyDown }

const int pulseCapacity  = 500;
const double maxRobotWidth = 25 * ticksPerCM;
const double maxRobotHight = 19 * ticksPerCM;

const double opacity    = 1.0;
const double ticksPerCM = 100;
const double spaceBetweenCups = 0.5 * ticksPerCM;
const double spaceBetweenLastCupAndWater = 1 * ticksPerCM;

const double cupSize      = 3 * ticksPerCM;
const double waterCupSize = 3.8 * ticksPerCM;
const double xColorOffset = cupSize / 2;
const double distInCup    = cupSize / 3;
const double paperWidthInCM = 29.7;
const double paperHightInCM = 21;
const double paperWidthInRobotMoves = paperWidthInCM * ticksPerCM;
const double paperHightInRobotMoves = paperHightInCM * ticksPerCM;
const double palleteHight = 7 * ticksPerCM;
final double paperWidth = min(paperWidthInRobotMoves, maxRobotWidth);
final double paperHight = min(paperHightInRobotMoves, maxRobotHight - palleteHight);
const double xOffset    = 0;
const double yOffset    = 0;
const double marginFactor = 0.97;
final double xMargin = (paperWidth * (1-marginFactor)) / 2;
final double yMargin = (paperHight * (1-marginFactor)) / 2;

const Offset dummyOffset = Offset(-1, -1);
final Offset waterOffset = Offset(5.5 * cupSize + 5 * spaceBetweenCups + waterCupSize / 2 + spaceBetweenLastCupAndWater + xColorOffset, maxRobotHight);
final Offset redOffset   = Offset(2   * cupSize + 2 * spaceBetweenCups + xColorOffset, maxRobotHight);
final Offset greenOffset = Offset(2   * cupSize + cupSize / 2 + spaceBetweenCups + xColorOffset, maxRobotHight);
final Offset blueOffset  = Offset(3   * cupSize + cupSize / 2 + spaceBetweenCups + xColorOffset, maxRobotHight);

final DrawingPoint upPoint    = DrawingPoint(location: dummyOffset, type: PointType.dummyUp, paint: Paint());
final DrawingPoint downPoint  = DrawingPoint(location: dummyOffset, type: PointType.dummyDown, paint: Paint());
final DrawingPoint startPoint = DrawingPoint(location: Offset(0, maxRobotHight), type: PointType.regular, paint: Paint());

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
