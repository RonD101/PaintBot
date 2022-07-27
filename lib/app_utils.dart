import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

enum RobotMove     { right, left, up, down, rightUp, rightDown, leftUp, leftDown, servoUp, servoThick, servoMiddle, servoLight, goHome }
enum UploadFlag    { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PulseStatus   { nextPulse, reuploadPulse, finishedPulses }
enum MenuSelection { strokeWidth, brushColor, settingMenu, testMenu }
enum TestSelection { square, rightUpAllWay, goHome }
enum PointType     { regular, dummyUp, dummyDown }

// Refill options
const int numPointForRefill  = 400; // Change for smaller/larger number of points needed for refill.
const int minRemainForRefill = 100; // Dont refill if you have only small amount of points left.

// Real painting options
const double opacity        = 0.8; // Mimic real brush color to screen.
const double penLightCM     = 0.2; // Adjust for real brush width
const double penThickCM     = 0.4;
      double lightWidth     = 0;
      double thickWidth     = 0;
const double paperWidthInCM = 29.7;
const double paperHightInCM = 21;

// Robot configs
const double ticksPerCM    = 100;               // Number of robot moves to achive 1 cm.
const double maxRobotWidth = 25 * ticksPerCM; // Maximum size of width
const double maxRobotHight = 19   * ticksPerCM; // Maximum size of height

// Spacing and offsets configs
const double spaceLastCupAndWater = 1    * ticksPerCM; 
const double spaceBetweenCups     = 0.5  * ticksPerCM;
const double spaceToCleaner       = 0.65 * ticksPerCM;
const double cupSize              = 3    * ticksPerCM;
const double waterCupSize         = 3.8  * ticksPerCM;
const double longDistClean        = 7    * ticksPerCM;
const double shortDistClean       = 1    * ticksPerCM;
const double palleteHight         = 7    * ticksPerCM;
const double xColorOffset         = 0.4  * ticksPerCM;
const double yColorOffset         = 0    * ticksPerCM;
const double distInCup            = 0.45 * cupSize;

// Scaling configs
const double paperWidthInRobotMoves = paperWidthInCM * ticksPerCM;
const double paperHightInRobotMoves = paperHightInCM * ticksPerCM;
final double paperWidth   = min(paperWidthInRobotMoves, maxRobotWidth);
final double paperHight   = min(paperHightInRobotMoves, maxRobotHight - palleteHight);
const double xOffset      = 0;
const double yOffset      = 0;
const double marginFactor = 1.0;
final double xMargin      = (paperWidth * (1 - marginFactor)) / 2;
final double yMargin      = (paperHight * (1 - marginFactor)) / 2;

// Paint and water offsets
const Offset waterOffset  = Offset(6 * cupSize + 5 * spaceBetweenCups + waterCupSize / 2 + spaceLastCupAndWater + xColorOffset, maxRobotHight - yColorOffset);
const Offset cleanOffset  = Offset(4 * cupSize + 4 * spaceBetweenCups + xColorOffset, maxRobotHight - 1.5 * cupSize - spaceBetweenCups - spaceToCleaner - yColorOffset);
final Offset yellowOffset = getColorOffset(0, 0);
final Offset orangeOffset = getColorOffset(0, 1);
final Offset redOffset    = getColorOffset(0, 2);
final Offset purpleOffset = getColorOffset(0, 3);
final Offset brownOffset  = getColorOffset(0, 4);
final Offset blackOffset  = getColorOffset(0, 5);
final Offset lgreenOffset = getColorOffset(1, 0);
final Offset dgreenOffset = getColorOffset(1, 1);
final Offset lblueOffset  = getColorOffset(1, 2);
final Offset dblueOffset  = getColorOffset(1, 3);
final Offset pinkOffset   = getColorOffset(1, 4);
final Offset whiteOffset  = getColorOffset(1, 5);

const Offset       dummyOffset = Offset(-1, -1);
final DrawingPoint upPoint     = DrawingPoint(location: dummyOffset, type: PointType.dummyUp, paint: Paint(), strokeWidth: lightWidth);
final DrawingPoint downPoint   = DrawingPoint(location: dummyOffset, type: PointType.dummyDown, paint: Paint(), strokeWidth: lightWidth);
final DrawingPoint startPoint  = DrawingPoint(location: const Offset(0, maxRobotHight), type: PointType.regular, paint: Paint(), strokeWidth: lightWidth);

// Firebase and esp32.
const int pulseCapacity     = 250;   // Each pulse to firebase contains 250 pairs of data - move and num.
const int maxNumOfCompMoves = 10000; // Due to esp32 memory limitations.
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
  final double    strokeWidth;
  const DrawingPoint({required this.location, required this.type, required this.paint, required this.strokeWidth});
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
        canvas.drawPoints(    PointMode.points, [curLoc, Offset(curLoc.dx + 0.1, curLoc.dy + 0.1)], pointList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class BotIcons {
  static const IconData undo        = Icons.undo_outlined;
  static const IconData restart     = Icons.restart_alt_outlined;
  static const IconData upload      = Icons.upload_file_outlined;
  static const IconData square      = Icons.crop_square_outlined;
  static const IconData rightUp     = Icons.turn_right_sharp;
  static const IconData goHome      = Icons.home_outlined;
  static const IconData stroke      = Icons.line_weight;
  static const IconData color       = Icons.color_lens_outlined;
  static const IconData settings    = Icons.settings_outlined;
  static const IconData test        = Icons.checklist_outlined;
  static const IconData calibration = Icons.aspect_ratio_outlined;
}

class ScaleData {
  double xScale = 0;
  double yScale = 0;
  double fScale = 0;
  double xBase  = 0;
  double yBase  = 0;
  double statusBar = 0;
  ScaleData(double width, double hight, this.statusBar) {
    final double mHight = hight - (kBottomNavigationBarHeight + statusBar); // remove menu height
    xScale = paperWidth / width;
    yScale = paperHight / mHight;
    fScale = min(xScale, yScale) * marginFactor;
    if (fScale == xScale) {
      xBase = xOffset + xMargin;
      yBase = ((paperHight - mHight * fScale) / 2) + yOffset + yMargin;
    } else {
      xBase = ((paperWidth -  width * fScale) / 2) + xOffset + xMargin;
      yBase = yOffset + yMargin;
    }
    lightWidth = (penLightCM * ticksPerCM) / fScale;
    thickWidth = (penThickCM * ticksPerCM) / fScale;
  }
}

Offset getColorOffset(int row, int col) {
  final double xOffset = cupSize * col + cupSize / 2 + spaceBetweenCups * col + xColorOffset;
  final double yOffset = maxRobotHight - ((cupSize + spaceBetweenCups) * row) - yColorOffset;
  return Offset(xOffset, yOffset);
}