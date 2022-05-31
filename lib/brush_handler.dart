import 'dart:ui';
import 'app_utils.dart';

void addRedBrush(List<DrawingPoint> points) {
  //points.add(DrawingPoint(pointLocation: dummyOffset, pointType: PointType.dummyUp, paint: Paint()));
  points.add(DrawingPoint(location: redOffset, type: PointType.regular, paint: Paint()));
  sweepBrushInCup(points);
}

void cleanBrush(List<DrawingPoint> points) {
  points.add(upPoint);
  points.add(DrawingPoint(location: waterOffset, type: PointType.regular, paint: Paint()));
  sweepBrushInCup(points);
}

void sweepBrushInCup(List<DrawingPoint> points) {
  final double lastX = points.last.location.dx;
  final double lastY = points.last.location.dy;
  points.add(downPoint);
  points.add(
      DrawingPoint(location: Offset(lastX + distInCup, lastY + distInCup), type: PointType.regular, paint: Paint()));
  points.add(
      DrawingPoint(location: Offset(lastX - distInCup, lastY + distInCup), type: PointType.regular, paint: Paint()));
  points.add(
      DrawingPoint(location: Offset(lastX - distInCup, lastY - distInCup), type: PointType.regular, paint: Paint()));
  points.add(
      DrawingPoint(location: Offset(lastX + distInCup, lastY - distInCup), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX, lastY), type: PointType.regular, paint: Paint()));
  points.add(upPoint);
}
