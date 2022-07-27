import 'package:flutter/material.dart';
import 'package:paint_bot/app_utils.dart';
import 'package:paint_bot/upload_handler.dart';
import 'package:paint_bot/bresenham_algo.dart';

// Black color
//  --------
//  |
//  |
//  | 
//  |
void upRightTest(ScaleData scaleData) async {
  List<DrawingPoint> points = [];
  points.add(downPoint);
  points.add(DrawingPoint(location: const Offset(100, 100), type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(100, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(200, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(upPoint);
  await uploadTest(points, scaleData); 
}

// Black color (this is actually a square)
//  --------
//  |      |
//  |      |
//  |      |
//  |      |
//  --------
void squareTest(ScaleData scaleData) async {
  List<DrawingPoint> points = [];
  points.add(downPoint);
  points.add(DrawingPoint(location: const Offset(300, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(300, 100), type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(200 , 100), type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(200 , 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(300, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(upPoint);
  await uploadTest(points, scaleData);
}

// Just go home.
void goHomeTest() async {
  List<CompMove> compressedMoves = [];
  compressedMoves.add(CompMove(num: 1, move: RobotMove.servoUp));
  compressedMoves.add(CompMove(num: 1, move: RobotMove.goHome));
  await startUploading(compressedMoves);
}

// This is a special test desined to calibrate the motors.
// It creates a perfect 1000x1000 square and is used to measure how many ticks the motors need to make a single cm.
// After results, change ticksPerCM in app_utils.dart
// NOTICE - THIS TEST MUST BE DONE USING A PEN AND NOT THE BRUSH - IT WILL NOT GO TO WATER/COLORS.
void calibrationTest() async {
  List<CompMove> compressedMoves = [];
  compressedMoves.add(CompMove(num: 1, move: RobotMove.servoUp));
  compressedMoves.add(CompMove(num: 1700, move: RobotMove.rightUp));
  compressedMoves.add(CompMove(num: 1, move: RobotMove.servoLight));
  compressedMoves.add(CompMove(num: 1000, move: RobotMove.right));
  compressedMoves.add(CompMove(num: 1000, move: RobotMove.up));
  compressedMoves.add(CompMove(num: 1000, move: RobotMove.left));
  compressedMoves.add(CompMove(num: 1000, move: RobotMove.down));
  compressedMoves.add(CompMove(num: 1, move: RobotMove.servoUp));
  compressedMoves.add(CompMove(num: 1, move: RobotMove.goHome));
  await startUploading(compressedMoves);
}

Future<void> uploadTest(List<DrawingPoint> points, ScaleData scaleData) async {
  final List<DrawingPoint> scaledPoints     = getScaledPoints(points, scaleData);
  final List<DrawingPoint> pointsWithColors = getPointsWithColors(scaledPoints);
  final List<DrawingPoint> smoothPoints     = getSmoothPoints(pointsWithColors);
  final List<DrawingPoint> bresenhamPoints  = globalBresenham(smoothPoints);
  final List<RobotMove>    robotMoves       = getRobotMoves(bresenhamPoints);
  final List<CompMove>     compressedMoves  = getCompressedMoves(robotMoves);
  await startUploading(compressedMoves);
}
