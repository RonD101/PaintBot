import 'package:flutter/material.dart';
import 'app_utils.dart';

void addColor(List<DrawingPoint> points, Color color) {
  addWater(points);
  cleanBrush(points, longDistClean);
  addWater(points);
  cleanBrush(points, shortDistClean);
  points.add(upPoint);
  points.add(downPoint);
  Offset colorOffset = yellowOffset;
  if (isSameColor(color, Colors.yellow)) {
    colorOffset = yellowOffset;
  } else if (isSameColor(color, Colors.orange)) {
    colorOffset = orangeOffset;
  }
  else if (isSameColor(color, Colors.red)) {
    colorOffset = redOffset;
  }
  else if (isSameColor(color, Colors.purple)) {
    colorOffset = purpleOffset;
  }
  else if (isSameColor(color, Colors.brown)) {
    colorOffset = brownOffset;
  }
  else if (isSameColor(color, Colors.lightGreen)) {
    colorOffset = lgreenOffset;
  }
  else if (isSameColor(color, Colors.green)) {
    colorOffset = dgreenOffset;
  }
  else if (isSameColor(color, Colors.lightBlue)) {
    colorOffset = lblueOffset;
  }
  else if (isSameColor(color, Colors.blue)) {
    colorOffset = dblueOffset;
  }
  else if (isSameColor(color, Colors.pink)) {
    colorOffset = pinkOffset;
  }
  else if (color.red == 0 && color.green == 0 && color.blue == 0) {
    colorOffset = blackOffset;
  }
  else if (color.red == 255 && color.green == 255 && color.blue == 255) {
    colorOffset = whiteOffset;
  }
  points.add(DrawingPoint(location: colorOffset, type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  sweepBrushInCup(points);
  sweepBrushInCup(points);
  points.add(upPoint);
  points.add(downPoint);
}

void addWater(List<DrawingPoint> points) {
  points.add(upPoint);
  points.add(downPoint);
  points.add(DrawingPoint(location: waterOffset, type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  sweepBrushInCup(points);
}

void sweepBrushInCup(List<DrawingPoint> points) {
  final double lastX = points.last.location.dx;
  final double lastY = points.last.location.dy;
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY - distInCup), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY - distInCup), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX + distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX - distInCup, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: Offset(lastX            , lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
}

void cleanBrush(List<DrawingPoint> points, double distClean) {
  points.add(upPoint);
  points.add(downPoint);
  points.add(DrawingPoint(location: cleanOffset, type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  final double lastX = points.last.location.dx;
  final double lastY = points.last.location.dy;
  points.add(DrawingPoint(location: Offset(lastX - distClean, lastY), type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: cleanOffset, type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
  points.add(DrawingPoint(location: cleanOffset, type: PointType.regular, paint: Paint(), strokeWidth: thickWidth));
}

bool isSameColor(Color first, MaterialColor second) {
  return first.red == second.red && first.green == second.green && first.blue == second.blue;
}