import 'dart:math';
import 'app_utils.dart';
import 'dart:ui';

List<DrawingPoint> globalBresenhamAlgo(List<DrawingPoint> points, double width, double height) {
  final double xScale = a4Width / (width * pixelToMM);
  final double yScale = a4Height / (height * pixelToMM);
  List<DrawingPoint> bresenhamPoints = [];
  List<DrawingPoint> scaledPoints = [];
  // scaledPoints.add(Point(0, height * yScale)); // bresenham from robot start to first point.
  for (var cur in points) {
    scaledPoints.add(DrawingPoint(
        pointLocation: Offset(cur.pointLocation.dx * xScale, cur.pointLocation.dy * yScale),
        paint: cur.paint,
        pointType: cur.pointType));
  }
  for (int i = 1; i < scaledPoints.length - 2; i++) {
    final DrawingPoint cur = scaledPoints[i];
    final DrawingPoint next = scaledPoints[i + 1];
    final Offset curLoc = cur.pointLocation;
    final Offset nextLoc = next.pointLocation;
    if (cur.pointType == PointType.regular && next.pointType != PointType.regular) {
      continue;
    }
    if (cur.pointType == PointType.dummyUp) {
      bresenhamPoints.add(cur);
      continue;
    } else if (cur.pointType == PointType.dummyDown) {
      final Offset prevLoc = scaledPoints[i - 2].pointLocation;
      bresenhamPoints +=
          localBresenhamAlgo(prevLoc.dx.round(), prevLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
      bresenhamPoints.add(cur);
      i++;
    } else {
      bresenhamPoints +=
          localBresenhamAlgo(curLoc.dx.round(), curLoc.dy.round(), nextLoc.dx.round(), nextLoc.dy.round());
    }
  }
  return bresenhamPoints;
}

List<DrawingPoint> localBresenhamAlgo(int x0, int y0, int x1, int y1) {
  List<DrawingPoint> bresenhamPoints = [];
  var dx = (x1 - x0).abs();
  var dy = (y1 - y0).abs();
  var sx = (x0 < x1) ? 1 : -1;
  var sy = (y0 < y1) ? 1 : -1;
  var err = dx - dy;
  while (true) {
    bresenhamPoints.add(DrawingPoint(
        pointLocation: Offset(x0.toDouble(), y0.toDouble()), paint: Paint(), pointType: PointType.regular));
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
  robotMoves.add(RobotMove.servoDown);
  for (int i = 0; i < bresenhamPoints.length - 1; i++) {
    final DrawingPoint cur = bresenhamPoints[i];
    final DrawingPoint next = bresenhamPoints[i + 1];
    if (next.pointType != PointType.regular) {
      continue;
    }
    if (cur.pointType == PointType.dummyDown) {
      robotMoves.add(RobotMove.servoDown);
      continue;
    }
    if (cur.pointType == PointType.dummyUp) {
      robotMoves.add(RobotMove.servoUp);
      continue;
    }
    final Point curLoc = Point(cur.pointLocation.dx, cur.pointLocation.dy);
    final Point nextLoc = Point(next.pointLocation.dx, next.pointLocation.dy);
    for (int j = 0; j < 3; j++) {
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
  }
  robotMoves.add(RobotMove.servoUp);
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
