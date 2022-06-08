import 'dart:math';
import 'package:flutter/material.dart';
import 'package:paint_bot/brush_handler.dart';
import 'app_utils.dart';

// points - DD rrr DU DD bbb DU
// scaled - DD rrr DU DD bbb DU
// color  - s0 DU DD w0w1w2 DU DD r0r1r2 DU DD rrr DU DD w0w1w2 DU DD b0b1b2 DU DD bbb DU DD w0w1w2

List<DrawingPoint> getPointsWithColors(List<DrawingPoint> scaledPoints) {
  List<DrawingPoint> pointsWithColor = [];
  pointsWithColor.add(startPoint);
  Color curColor = scaledPoints[1].paint.color;
  addColor(pointsWithColor, curColor);
  for (int i = 1; i < scaledPoints.length - 1; i++) {
    final DrawingPoint cur = scaledPoints[i];
    final DrawingPoint next = scaledPoints[i + 1];
    if (cur.type == PointType.dummyUp && next.type == PointType.dummyDown) {
      if (curColor != scaledPoints[i + 2].paint.color) {
        curColor = scaledPoints[i + 2].paint.color;
        addColor(pointsWithColor, curColor);
      }
      i++;
    } else {
      pointsWithColor.add(cur);
    }
  }
  cleanBrush(pointsWithColor);
  return pointsWithColor;
}

List<DrawingPoint> getScaledPoints(List<DrawingPoint> points, double width, double height) {
  height -= kBottomNavigationBarHeight;
  final double xScale = a4Width / width;
  final double yScale = a4Height / height;
  final double fScale = min(xScale, yScale);
  final double xBase;
  final double yBase;
  if (fScale == xScale) {
    xBase = 0;
    yBase = ((a4Height - height * fScale) / 2) + xOffset;
  } else {
    xBase = ((a4Width - width * fScale) / 2) + yOffset;
    yBase = 0;
  }
  List<DrawingPoint> scaledPoints = [];
  for (var cur in points) {
    final Offset scaledP = Offset(xBase + cur.location.dx * fScale, yBase + cur.location.dy * fScale);
    scaledPoints.add(DrawingPoint(location: scaledP, type: cur.type, paint: cur.paint));
  }
  return scaledPoints;
}

// color     - s0 DU DD w0w1w2 DU DD r0r1r2 DU DD rrr DU DD w0w1w2 DU DD b0b1b2 DU DD bbb DU DD w0w1w2
// bresenham - DU b(s0, w0) DD b(w0, w1) b(w1, w2) DU b(w2, r0) DD b(r0, r1) b(r1, r2) DU b(r2, r) DD b(r, r) b(r, r) DU b(r, w0) DD b(w0, w1) b(w1, w2) DU b(w2, b0) DD b(b0, b1) b(b1, b2) DU b(b2, b) DD b(b, b) b(b, b) DU b(b, w0) DD b(w0, w1) b(w1, w2)
List<DrawingPoint> globalBresenham(List<DrawingPoint> pointsWithColors) {
  List<DrawingPoint> bresenhamPoints = [];
  for (int i = 0; i < pointsWithColors.length - 1; i++) {
    final DrawingPoint cur = pointsWithColors[i];
    final DrawingPoint next = pointsWithColors[i + 1];
    final Offset curLoc = cur.location;
    final Offset nextLoc = next.location;
    if (cur.type == PointType.regular && next.type == PointType.regular) {
      bresenhamPoints += localBresenham(curLoc.dx.round(), curLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
    } else if (cur.type == PointType.regular && next.type != PointType.regular) {
      continue;
    } else if (cur.type == PointType.dummyUp) {
      bresenhamPoints.add(upPoint);
    } else if (cur.type == PointType.dummyDown) {
      final Offset prevLoc = pointsWithColors[i - 2].location;
      bresenhamPoints += localBresenham(prevLoc.dx.round(), prevLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
      bresenhamPoints.add(downPoint);
    }
  }
  return bresenhamPoints;
}

List<DrawingPoint> localBresenham(int x0, int y0, int x1, int y1) {
  List<DrawingPoint> bresenhamPoints = [];
  var dx = (x1 - x0).abs();
  var dy = (y1 - y0).abs();
  var sx = (x0 < x1) ? 1 : -1;
  var sy = (y0 < y1) ? 1 : -1;
  var err = dx - dy;
  while (true) {
    bresenhamPoints
        .add(DrawingPoint(location: Offset(x0.toDouble(), y0.toDouble()), type: PointType.regular, paint: Paint()));
    if ((x0 == x1) && (y0 == y1)) {
      break;
    }
    var e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x0 += sx;
    }
    if (e2 < dx) {
      err += dx;
      y0 += sy;
    }
  }
  return bresenhamPoints;
}

// bresenham - DU b(s0, w0) DD b(w0, w1) b(w1, w2) DU b(w2, r0) DD b(r0, r1) b(r1, r2) DU b(r2, r) DD b(r, r) b(r, r) DU b(r, w0) DD b(w0, w1) b(w1, w2) DU b(w2, b0) DD b(b0, b1) b(b1, b2) DU b(b2, b) DD b(b, b) b(b, b) DU b(b, w0) DD b(w0, w1) b(w1, w2)
// robot     - SU mmmmmmmmm SD mmmmmmmmmmmmmmmmmmm SU mmmmmmmmm SD mmmmmmmmmmmmmmmmmmm SU mmmmmmmm SD mmmmmmmmmmmmmmm SU mmmmmmmm SD mmmmmmmmmmmmmmmmmmm SU mmmmmmmmm SD mmmmmmmmmmmmmmmmmmm SU mmmmmmmm SD mmmmmmmmmmmmmmm SU mmmmmmmm SD mmmmmmmmmmmmmmmmmmm SU GH
List<RobotMove> getRobotMovesFromBresenham(List<DrawingPoint> bresenhamPoints) {
  List<RobotMove> robotMoves = [];
  for (int i = 0; i < bresenhamPoints.length - 1; i++) {
    final DrawingPoint cur = bresenhamPoints[i];
    final DrawingPoint next = bresenhamPoints[i + 1];
    if (next.type != PointType.regular) {
      continue;
    }
    if (cur.type == PointType.dummyDown) {
      robotMoves.add(RobotMove.servoDown);
      continue;
    }
    if (cur.type == PointType.dummyUp) {
      robotMoves.add(RobotMove.servoUp);
      continue;
    }
    final Point curLoc = Point(cur.location.dx, cur.location.dy);
    final Point nextLoc = Point(next.location.dx, next.location.dy);
    if (curLoc.x < nextLoc.x && curLoc.y == nextLoc.y) {
      robotMoves.add(RobotMove.right);
    } else if (curLoc.x > nextLoc.x && curLoc.y == nextLoc.y) {
      robotMoves.add(RobotMove.left);
    } else if (curLoc.x == nextLoc.x && curLoc.y < nextLoc.y) {
      robotMoves.add(RobotMove.down);
    } else if (curLoc.x == nextLoc.x && curLoc.y > nextLoc.y) {
      robotMoves.add(RobotMove.up);
    } else if (curLoc.x < nextLoc.x && curLoc.y < nextLoc.y) {
      robotMoves.add(RobotMove.rightDown);
      robotMoves.add(RobotMove.rightDown);
    } else if (curLoc.x < nextLoc.x && curLoc.y > nextLoc.y) {
      robotMoves.add(RobotMove.rightUp);
      robotMoves.add(RobotMove.rightUp);
    } else if (curLoc.x > nextLoc.x && curLoc.y < nextLoc.y) {
      robotMoves.add(RobotMove.leftDown);
      robotMoves.add(RobotMove.leftDown);
    } else if (curLoc.x > nextLoc.x && curLoc.y > nextLoc.y) {
      robotMoves.add(RobotMove.leftUp);
      robotMoves.add(RobotMove.leftUp);
    }
  }
  robotMoves.add(RobotMove.servoUp);
  robotMoves.add(RobotMove.goHome);
  return robotMoves;
}

List<CompMove> compressMoves(List<RobotMove> robotMoves) {
  List<CompMove> out = [];
  for (RobotMove m in robotMoves) {
    if (out.isNotEmpty && m == out.last.move) {
      out.last.num++;
    } else {
      out.add(CompMove(num: 1, move: m));
    }
  }
  return out;
}
