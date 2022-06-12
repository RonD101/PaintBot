import 'package:flutter/material.dart';
import 'package:paint_bot/app_utils.dart';
import 'package:paint_bot/upload_handler.dart';
import 'package:paint_bot/bresenham_algo.dart';
import 'brush_handler.dart';

const double width = 683.428;
const double height = 411.43;

void rightUpAllWayTest() async {
  List<DrawingPoint> points = [];

  points.add(downPoint);
  points.add(DrawingPoint(location: const Offset(0, 388.42857), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(644.42857, 388.42857), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(644.42857, 0), type: PointType.regular, paint: Paint()));
  await uploadTest(points);
}

void squareTest() async {
  List<DrawingPoint> points = [];
  addColor(points, Colors.red);
  points.add(downPoint);
  points.add(DrawingPoint(location: const Offset(100, 10) , type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(100, 100), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(10 , 100), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(10 , 10) , type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: const Offset(100, 10) , type: PointType.regular, paint: Paint()));
  await uploadTest(points);
}

void goHomeTest() async {
  List<CompMove> compressedMoves = [];
  compressedMoves.add(CompMove(num: 1, move: RobotMove.servoUp));
  compressedMoves.add(CompMove(num: 1, move: RobotMove.goHome));
  await startUploading(compressedMoves);
}

Future<void> uploadTest(List<DrawingPoint> points) async {
  final List<DrawingPoint> scaledPoints = getScaledPoints(points, width, height);
  final List<DrawingPoint> bresenhamPoints = globalBresenham(scaledPoints);
  final List<RobotMove> robotMoves = getRobotMoves(bresenhamPoints);
  robotMoves.add(RobotMove.goHome);
  final List<CompMove> compressedMoves = getCompressedMoves(robotMoves);
  await startUploading(compressedMoves);
}
