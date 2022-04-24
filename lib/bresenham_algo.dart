import 'dart:math';
import 'package:flutter/foundation.dart';

enum RobotMove { right, left, up, down, rightUp, rightDown, leftUp, leftDown }

List<Point> getBresenhamPoints(int x0, int y0, int x1, int y1) {
  List<Point> bresenhamPoints = [];
  var dx = (x1 - x0).abs();
  var dy = (y1 - y0).abs();
  var sx = (x0 < x1) ? 1 : -1;
  var sy = (y0 < y1) ? 1 : -1;
  var err = dx - dy;

  while (true) {
    bresenhamPoints.add(Point(x0, y0));
    debugPrint(x0.toString() + " " + y0.toString());
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

List<RobotMove> getRobotMovesFromBresenham(List<Point> bresenhamPoints) {
  List<RobotMove> robotMoves = [];
  for (int i = 0; i < bresenhamPoints.length - 1; i++) {
    Point cur = bresenhamPoints[i];
    Point next = bresenhamPoints[i + 1];
    
    if (cur.y == next.y && cur.x < next.x) {
      robotMoves.add(RobotMove.right);
    } else if (cur.y == next.y && cur.x > next.x) {
      robotMoves.add(RobotMove.left);
    } else if (cur.x == next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.up);
    } else if (cur.x == next.x && cur.y > next.y) {
      robotMoves.add(RobotMove.down);
    } else if (cur.x < next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.rightUp);
    } else if (cur.x < next.x && cur.y > next.y) {
      robotMoves.add(RobotMove.rightDown);
    } else if (cur.x > next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.leftUp);
    } else if (cur.x > next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.leftDown);
    }
    debugPrint(robotMoves.last.toString());
  }
  return robotMoves;
}
