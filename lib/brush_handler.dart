import 'package:flutter/material.dart';
import 'app_utils.dart';

void addColor(List<DrawingPoint> points, Color color) {
  addWater(points);
  points.add(upPoint);
  points.add(downPoint);
  if (color.red == Colors.red.red) {
    points.add(DrawingPoint(location: redOffset  , type: PointType.regular, paint: Paint()));
  } else if (color.green == Colors.green.green) {
    points.add(DrawingPoint(location: greenOffset, type: PointType.regular, paint: Paint()));
  } else if (color.blue == Colors.blue.blue) {
    points.add(DrawingPoint(location: blueOffset , type: PointType.regular, paint: Paint()));
  }
  sweepBrushInCup(points);
  points.add(upPoint);
  points.add(downPoint);
}

void addWater(List<DrawingPoint> points) {
  points.add(upPoint);
  points.add(downPoint);
  points.add(DrawingPoint(location: waterOffset, type: PointType.regular, paint: Paint()));
  sweepBrushInCup(points);
  sweepBrushInCup(points);
  cleanBrush(points);
}

void sweepBrushInCup(List<DrawingPoint> points) {
  final double lastX = points.last.location.dx;
  final double lastY = points.last.location.dy;
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY - distInCup), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY - distInCup), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint()));
}

void cleanBrush(List<DrawingPoint> points) {
  points.add(upPoint);
  points.add(downPoint);
  points.add(DrawingPoint(location: cleanerOffset, type: PointType.regular, paint: Paint()));
  final double lastX = points.last.location.dx;
  final double lastY = points.last.location.dy;
  points.add(DrawingPoint(location: Offset(lastX - distOfCleaner, lastY), type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: cleanerOffset, type: PointType.regular, paint: Paint()));
  points.add(DrawingPoint(location: cleanerOffset, type: PointType.regular, paint: Paint()));
}