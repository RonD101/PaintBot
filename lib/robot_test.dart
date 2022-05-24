import 'package:flutter/cupertino.dart';
import 'package:paint_bot/app_utils.dart';
import 'package:paint_bot/upload_handler.dart';
import 'package:paint_bot/bresenham_algo.dart';

const double width = 683.428;
const double height = 411.43;

void drawRightLine() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 10), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(100, 10), pointType: PointType.regular));

  await uploadTest(points);
}

void drawFullWidth() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(0, 0), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(683.43, 0), pointType: PointType.regular));

  await uploadTest(points);
}

void drawRightUpAllWay() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(0, 388.42857), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(644.42857, 388.42857), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(644.42857, 0), pointType: PointType.regular));
  await uploadTest(points);
}

void drawSquare() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 10), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(100, 10), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(100, 100), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 100), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 10), pointType: PointType.regular));

  await uploadTest(points);
}

void drawX() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 10), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(100, 100), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyUp));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(10, 100), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: const Offset(100, 10), pointType: PointType.regular));

  await uploadTest(points);
}

Future<void> uploadTest(List<DrawingPoint> points) async {
  final List<DrawingPoint> bresenhamPoints = globalBresenhamAlgo(points, width, height);
  final List<RobotMove> robotMoves = getRobotMovesFromBresenham(bresenhamPoints);
  robotMoves.add(RobotMove.goHome);
  final List<CompMove> compressedMoves = compressMoves(robotMoves);
  await startUploading(compressedMoves);
}
