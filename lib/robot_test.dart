import 'package:flutter/material.dart';
import 'package:paint_bot/app_utils.dart';
import 'package:paint_bot/upload_handler.dart';
import 'package:paint_bot/bresenham_algo.dart';

void upRightTest(ScaleData scaleData) async {
  List<DrawingPoint> points = [];
  points.add(downPoint);
  points.add(DrawingPoint(location: const Offset(100, 100), type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(100, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(DrawingPoint(location: const Offset(200, 10) , type: PointType.regular, paint: Paint(), strokeWidth: lightWidth));
  points.add(upPoint);
  await uploadTest(points, scaleData); 
}

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

void goHomeTest() async {
  List<CompMove> compressedMoves = [];
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
