import 'dart:math';
import 'package:flutter/material.dart';
import 'package:paint_bot/brush_handler.dart';
import 'app_utils.dart';

// scaled - DD rrr DU DD bbb DU
List<DrawingPoint> getScaledPoints(List<DrawingPoint> points, double width, double hight, double statusBar) {
  hight -= (kBottomNavigationBarHeight + statusBar); // remove menu height
  final double xScale = paperWidth / width;
  final double yScale = paperHight / hight;
  final double fScale = min(xScale, yScale) * marginFactor;
  final double xBase;
  final double yBase;
  if (fScale == xScale) {
    xBase = xOffset + xMargin;
    yBase = ((paperHight - hight * fScale) / 2) + yOffset + yMargin;
  } else {
    xBase = ((paperWidth - width * fScale) / 2) + xOffset + xMargin;
    yBase = yOffset + yMargin;
  }
  List<DrawingPoint> scaledPoints = [];
  for (var cur in points) {
    final Offset scaledP = Offset(xBase + cur.location.dx * fScale, yBase + (cur.location.dy - statusBar) * fScale);
    scaledPoints.add(DrawingPoint(location: scaledP, type: cur.type, paint: cur.paint));
  }
  return scaledPoints;
}

// color - s0 DU DD w0w1w2 DU DD r0r1r2 DU DD rrr DU DD w0w1w2 DU DD b0b1b2 DU DD bbb DU DD w0w1w2
List<DrawingPoint> getPointsWithColors(List<DrawingPoint> scaledPoints) {
  int numOfCurColor = 0;
  List<DrawingPoint> pointsWithColor = [];
  pointsWithColor.add(startPoint);
  Color curColor = scaledPoints[1].paint.color; // first color
  addColor(pointsWithColor, curColor);
  for (int i = 1; i < scaledPoints.length - 1; i++) {
    final DrawingPoint cur = scaledPoints[i];
    final DrawingPoint nex = scaledPoints[i + 1];
    if (cur.type == PointType.dummyUp && nex.type == PointType.dummyDown) {
      if (curColor != scaledPoints[i + 2].paint.color) {
        curColor = scaledPoints[i + 2].paint.color;
        addColor(pointsWithColor, curColor);
        numOfCurColor = 0;
      }
      else { 
        pointsWithColor.add(cur);
        pointsWithColor.add(nex);
      }
      i++;
    } else {
      pointsWithColor.add(cur);
      if (cur.type == PointType.regular) {
        numOfCurColor++;
      }
      if (numOfCurColor > numPointForRefill) {
        numOfCurColor = 0;
        addColor(pointsWithColor, curColor);
      }
    }
  }
  addWater(pointsWithColor); // every draw ends with water.
  cleanBrush(pointsWithColor);
  for (var p in pointsWithColor) {
    p.printPoint();
  }  
  return pointsWithColor;
}

// smooth - s0
//          DU DD (s0x, w0y)w0w1w2
//          DU DD (w2x, r0y)r0r1r2
//          DU DD (r2x, ry)rrr
//          DU DD (rx, w0y)w0w1w2
//          DU DD (w2x, b0y)b0b1b2
//          DU DD (b2x, by)bbb
//          DU DD (bx, w0y)w0w1w2
List<DrawingPoint> getSmoothPoints(List<DrawingPoint> pointsWithColors) {
  List<DrawingPoint> smoothPoints = [];
  for (int i = 0; i < pointsWithColors.length - 1; i++) {
    final DrawingPoint cur = pointsWithColors[i];
    final DrawingPoint nex = pointsWithColors[i + 1];
    if (cur.type == PointType.dummyUp && nex.type == PointType.dummyDown) {
      smoothPoints.add(upPoint);
      smoothPoints.add(downPoint);
      final double prevX = pointsWithColors[i - 1].location.dx;
      final double nextY = pointsWithColors[i + 2].location.dy;
      smoothPoints.add(DrawingPoint(location: Offset(prevX, nextY), type: PointType.regular, paint: Paint()));
      i++;
    } else {
      smoothPoints.add(cur);
    }
  }
  return smoothPoints;
}

// bresenham - DU
//             B(s0, (s0x, w0y)) B((s0x, w0y), w0) DD B(w0, w1) B(w1, w2) DU
//             B(w2, (w2x, r0y)) B((w2x, r0y), r0) DD B(r0, r1) B(r1, r2) DU
//             B(r2, (r2x, ry))  B((r2x, ry) , r)  DD B(r , r)  B(r , r)  DU
//             B(r , (rx , w0y)) B((rx , w0y), w0) DD B(w0, w1) B(w1, w2) DU
//             B(w2, (w2x, b0y)) B((w2x, b0y), b0) DD B(b0, b1) B(b1, b2) DU
//             B(b2, (b2x, by))  B((b2x, by) , b)  DD B(b , b)  B(b , b)  DU
//             B(b , (bx , w0y)) B((bx , w0y), w0) DD B(w0, w1) B(w1, w2)
List<DrawingPoint> globalBresenham(List<DrawingPoint> smoothPoints) {
  List<DrawingPoint> bresenhamPoints = [];
  for (int i = 0; i < smoothPoints.length - 1; i++) {
    final PointType curType = smoothPoints[i].type;
    final PointType nexType = smoothPoints[i + 1].type;
    final int curX = smoothPoints[i].location.dx.round();
    final int curY = smoothPoints[i].location.dy.round();
    final int nexX = smoothPoints[i + 1].location.dx.round();
    final int nexY = smoothPoints[i + 1].location.dy.round();
    if (curType == PointType.regular && nexType == PointType.regular) {
      bresenhamPoints += localBresenham(curX, curY, nexX, nexY);
    } else if (curType == PointType.regular && nexType != PointType.regular) {
      continue;
    } else if (curType == PointType.dummyUp) {
      bresenhamPoints.add(upPoint);
    } else if (curType == PointType.dummyDown) {
      final int beforeUpX = smoothPoints[i - 2].location.dx.round();
      final int beforeUpY = smoothPoints[i - 2].location.dy.round();
      final int afterLogisticX = smoothPoints[i + 2].location.dx.round();
      final int afterLogisticY = smoothPoints[i + 2].location.dy.round();
      bresenhamPoints += localBresenham(beforeUpX, beforeUpY, nexX, nexY);
      bresenhamPoints += localBresenham(nexX, nexY, afterLogisticX, afterLogisticY);
      bresenhamPoints.add(downPoint);
      i++;
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
    bresenhamPoints.add(DrawingPoint(location: Offset(x0.toDouble(), y0.toDouble()), type: PointType.regular, paint: Paint()));
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

// robot - SU mmm SD mmm SU mmm SD mmm SU mmm SD mmm SU mmm SD mmm SU mmm SD mmm SU mmm SD mmm SU mmm SD mmm SU GH
List<RobotMove> getRobotMoves(List<DrawingPoint> bresenhamPoints) {
  List<RobotMove> robotMoves = [];
  for (int i = 0; i < bresenhamPoints.length - 1; i++) {
    final DrawingPoint cur = bresenhamPoints[i];
    final DrawingPoint nex = bresenhamPoints[i + 1];
    if (nex.type != PointType.regular) {
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
    final Point nexLoc = Point(nex.location.dx, nex.location.dy);
    if (       curLoc.x <  nexLoc.x && curLoc.y == nexLoc.y) {
      robotMoves.add(RobotMove.right);
    } else if (curLoc.x >  nexLoc.x && curLoc.y == nexLoc.y) {
      robotMoves.add(RobotMove.left);
    } else if (curLoc.x == nexLoc.x && curLoc.y < nexLoc.y) {
      robotMoves.add(RobotMove.down);
    } else if (curLoc.x == nexLoc.x && curLoc.y > nexLoc.y) {
      robotMoves.add(RobotMove.up);
    } else if (curLoc.x <  nexLoc.x && curLoc.y < nexLoc.y) {
      robotMoves.add(RobotMove.rightDown);
      robotMoves.add(RobotMove.rightDown);
    } else if (curLoc.x <  nexLoc.x && curLoc.y > nexLoc.y) {
      robotMoves.add(RobotMove.rightUp);
      robotMoves.add(RobotMove.rightUp);
    } else if (curLoc.x >  nexLoc.x && curLoc.y < nexLoc.y) {
      robotMoves.add(RobotMove.leftDown);
      robotMoves.add(RobotMove.leftDown);
    } else if (curLoc.x >  nexLoc.x && curLoc.y > nexLoc.y) {
      robotMoves.add(RobotMove.leftUp);
      robotMoves.add(RobotMove.leftUp);
    }
  }
  robotMoves.add(RobotMove.servoUp);
  robotMoves.add(RobotMove.goHome);
  return robotMoves;
}

List<CompMove> getCompressedMoves(List<RobotMove> robotMoves) {
  List<CompMove> compressedMoves = [];
  for (RobotMove m in robotMoves) {
    if (compressedMoves.isNotEmpty && m == compressedMoves.last.move) {
      compressedMoves.last.num++;
    } else {
      compressedMoves.add(CompMove(num: 1, move: m));
    }
  }
  return compressedMoves;
}
