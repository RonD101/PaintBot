import 'package:flutter/cupertino.dart';
import 'package:paint_bot/app_utils.dart';
import 'package:paint_bot/upload_handler.dart';
import 'package:paint_bot/bresenham_algo.dart';

const double width = 683.428;
const double height = 411.43;

void rightUpAllWayTest() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyDown, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(0, 388.42857), pointType: PointType.regular, paint: Paint()));
  points.add(
      DrawingPoint(pointLocation: const Offset(644.42857, 388.42857), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(644.42857, 0), pointType: PointType.regular, paint: Paint()));
  await uploadTest(points);
}

void squareTest() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyDown, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(100, 10), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(100, 100), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(10, 100), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: const Offset(10, 10), pointType: PointType.regular, paint: Paint()));
  await uploadTest(points);
}

void goHomeTest() async {
  List<DrawingPoint> points = [];
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyUp, paint: Paint()));
  await uploadTest(points);
}

Future<void> uploadTest(List<DrawingPoint> points) async {
  final List<DrawingPoint> bresenhamPoints = globalBresenhamAlgo(points, width, height);
  final List<RobotMove> robotMoves = getRobotMovesFromBresenham(bresenhamPoints);
  robotMoves.add(RobotMove.goHome);
  final List<CompMove> compressedMoves = compressMoves(robotMoves);
  await startUploading(compressedMoves);
}
