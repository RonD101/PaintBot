import 'dart:math';
import 'package:flutter/material.dart';
import 'app_utils.dart';

List<DrawingPoint> getScaledPoints(List<DrawingPoint> points, double width, double height) {
  final double xScale = a4Width / width;
  final double yScale = a4Height / height;
  final double fScale = min(xScale, yScale);
  navBarHeight = kBottomNavigationBarHeight * yScale;
  List<DrawingPoint> scaledPoints = [];
  for (var cur in points) {
    scaledPoints.add(DrawingPoint(
        location: Offset(cur.location.dx * fScale, cur.location.dy * fScale), type: cur.type, paint: Paint()));
  }
  return scaledPoints;
}

List<DrawingPoint> globalBresenham(List<DrawingPoint> scaledPoints) {
  final Offset startingPoint = scaledPoints[2].location;
  List<DrawingPoint> bresenhamPoints = [];
  bresenhamPoints.add(upPoint);
  bresenhamPoints +=
      localBresenham(0, (a4Height - navBarHeight).round(), startingPoint.dx.round(), startingPoint.dy.round());
  bresenhamPoints.add(downPoint);
  for (int i = 2; i < scaledPoints.length - 1; i++) {
    final DrawingPoint cur = scaledPoints[i];
    final DrawingPoint next = scaledPoints[i + 1];
    final Offset curLoc = cur.location;
    final Offset nextLoc = next.location;
    if (cur.type == PointType.regular && next.type == PointType.regular) {
      bresenhamPoints += localBresenham(curLoc.dx.round(), curLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
    } else if (cur.type == PointType.regular && next.type != PointType.regular) {
      continue;
    } else if (cur.type == PointType.dummyUp) {
      bresenhamPoints.add(upPoint);
    } else if (cur.type == PointType.dummyDown) {
      final Offset prevLoc = scaledPoints[i - 2].location;
      bresenhamPoints += localBresenham(prevLoc.dx.round(), prevLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
      bresenhamPoints.add(downPoint);
      continue;
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
