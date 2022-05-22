import 'dart:ui';
import 'app_utils.dart';
import 'bresenham_algo.dart';
import 'upload_handler.dart';

void addRedBrush(List<DrawingPoint> points) {
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyUp));
  points.add(DrawingPoint(paint: Paint(), pointLocation: redOffset, pointType: PointType.regular));
  sweepBrushInCup(points);
}

void cleanBrush(List<DrawingPoint> points) {
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyUp));
  points.add(DrawingPoint(paint: Paint(), pointLocation: waterOffset, pointType: PointType.regular));
  sweepBrushInCup(points);
}

void sweepBrushInCup(List<DrawingPoint> points) {
  final double lastX = points.last.pointLocation.dx;
  final double lastY = points.last.pointLocation.dy;
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyDown));
  points.add(DrawingPoint(paint: Paint(), pointLocation: Offset(lastX + travelDistInsideCup, lastY + travelDistInsideCup), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: Offset(lastX - travelDistInsideCup, lastY + travelDistInsideCup), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: Offset(lastX - travelDistInsideCup, lastY - travelDistInsideCup), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: Offset(lastX + travelDistInsideCup, lastY - travelDistInsideCup), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: Offset(lastX, lastY), pointType: PointType.regular));
  points.add(DrawingPoint(paint: Paint(), pointLocation: dummyOffset, pointType: PointType.dummyUp));
}
