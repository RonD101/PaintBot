import 'dart:ui';
import 'app_utils.dart';

void addRedBrush(List<DrawingPoint> points) {
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyUp, paint: Paint()));
  points.add(DrawingPoint(pointLocation: redOffset, pointType: PointType.regular, paint: Paint()));
  sweepBrushInCup(points);
}

void cleanBrush(List<DrawingPoint> points) {
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyUp, paint: Paint()));
  points.add(DrawingPoint(pointLocation: waterOffset, pointType: PointType.regular, paint: Paint()));
  sweepBrushInCup(points);
}

void sweepBrushInCup(List<DrawingPoint> points) {
  final double lastX = points.last.pointLocation.dx;
  final double lastY = points.last.pointLocation.dy;
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyDown, paint: Paint()));
  points.add(DrawingPoint(
      pointLocation: Offset(lastX + distInCup, lastY + distInCup), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(
      pointLocation: Offset(lastX - distInCup, lastY + distInCup), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(
      pointLocation: Offset(lastX - distInCup, lastY - distInCup), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(
      pointLocation: Offset(lastX + distInCup, lastY - distInCup), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: Offset(lastX, lastY), pointType: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyUp, paint: Paint()));
}
