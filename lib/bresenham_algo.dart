import 'dart:math';
import 'dart:ui';
import 'draw_screen.dart';

enum RobotMove { right, left, up, down, rightUp, rightDown, leftUp, leftDown }

List<Point> globalBresenhamAlgo(List<DrawingPoint> points, double xScale, double yScale) {
  List<Point> bresenhamPoints = [];
  List<DrawingPoint> scaledPoints = [];
  for (var cur in points) {
    if (cur.pointLocation == dummyPoint) {
      scaledPoints.add(DrawingPoint(pointLocation: dummyPoint, paint: cur.paint));
    } else {
      scaledPoints.add(DrawingPoint(
          pointLocation: Offset(cur.pointLocation.dx * xScale, cur.pointLocation.dy * yScale), paint: cur.paint));
    }
  }
  for (int i = 0; i < scaledPoints.length - 1; i++) {
    var cur = scaledPoints[i].pointLocation;
    var next = scaledPoints[i + 1].pointLocation;
    if (cur == dummyPoint) {
      continue;
    }
    if (next == dummyPoint) {
      if (i + 2 == scaledPoints.length) {
        continue;
      }
      next = scaledPoints[i + 2].pointLocation;
    }
    bresenhamPoints += localBresenhamAlgo(cur.dx.round(), cur.dy.round(), next.dx.round(), next.dy.round());
  }
  return bresenhamPoints;
}

List<Point> localBresenhamAlgo(int x0, int y0, int x1, int y1) {
  List<Point> bresenhamPoints = [];
  var dx = (x1 - x0).abs();
  var dy = (y1 - y0).abs();
  var sx = (x0 < x1) ? 1 : -1;
  var sy = (y0 < y1) ? 1 : -1;
  var err = dx - dy;
  while (true) {
    bresenhamPoints.add(Point(x0, y0));
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
    if (cur.x < next.x && cur.y == next.y) {
      robotMoves.add(RobotMove.right);
    } else if (cur.x < next.x && cur.y == next.y) {
      robotMoves.add(RobotMove.left);
    } else if (cur.x == next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.down);
    } else if (cur.x == next.x && cur.y > next.y) {
      robotMoves.add(RobotMove.up);
    } else if (cur.x < next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.rightDown);
    } else if (cur.x < next.x && cur.y > next.y) {
      robotMoves.add(RobotMove.rightUp);
    } else if (cur.x > next.x && cur.y < next.y) {
      robotMoves.add(RobotMove.leftDown);
    } else if (cur.x > next.x && cur.y > next.y) {
      robotMoves.add(RobotMove.leftUp);
    }
  }
  return robotMoves;
}
