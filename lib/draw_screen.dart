import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'bresenham_algo.dart';
import 'dart:math';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
const Offset dummyPoint = Offset(-1, -1);
const double a4Width = 210;
const double a4Height = 297;
const double pixelToMM = 0.26458333;

class DrawerScreen extends StatefulWidget {
  final double height;
  final double width;
  const DrawerScreen({Key? key, required this.height, required this.width}) : super(key: key);
  @override
  DrawState createState() => DrawState(height, width);
}

class DrawState extends State<DrawerScreen> {
  Color selectedColor = Colors.red;
  double strokeWidth = 3.0;
  List<DrawingPoint> points = [];
  List<DrawingPoint> scaledPoints = [];
  List<Point> bresenhamPoints = [];
  List<RobotMove> robotMoves = [];
  double xScale = 0.0;
  double yScale = 0.0;
  bool displayMenu = false;
  double opacity = 1.0;
  MenuSelection selectedMenu = MenuSelection.strokeWidth;

  DrawState(double height, double width) {
    xScale = a4Width / (width * pixelToMM);
    yScale = a4Height / (height * pixelToMM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.only(left: 60.0, right: 60.0),
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: const Color.fromRGBO(255, 215, 0, 1)),
          child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[createStrokeWidget(), createColorsWidget(), createSettingsWidget()],
                  ),
                  createMenuWidget()
                ],
              )),
        ),
      ),
      body: drawUserInput(context),
    );
  }

  GestureDetector drawUserInput(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          points.add(DrawingPoint(
              pointLocation: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = StrokeCap.round
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth));
        });
      },
      onPanStart: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          points.add(DrawingPoint(
              pointLocation: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = StrokeCap.round
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth));
        });
      },
      onPanEnd: (details) {
        setState(() {
          points.add(DrawingPoint(pointLocation: dummyPoint, paint: Paint()));
          //for (var p in points) {
          //p.printPoint();
          //}
          //debugPrint("************** NEW LINE ***************");
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: DrawingPainter(
          pointsList: points,
        ),
      ),
    );
  }

  AnimatedOpacity createMenuWidget() {
    return AnimatedOpacity(
        opacity: displayMenu ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        child: Visibility(
          child: selectCurrentMenu(),
          visible: displayMenu,
        ));
  }

  Row selectCurrentMenu() {
    if (selectedMenu == MenuSelection.strokeWidth) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getWidthCircleList());
    }
    if (selectedMenu == MenuSelection.brushColor) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getColoredCircleList());
    }
    if (selectedMenu == MenuSelection.settingMenu) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getSettingsList());
    }
    throw Exception("Invalid menu selected");
  }

  IconButton createStrokeWidget() {
    return IconButton(
        icon: const Icon(Icons.line_weight),
        onPressed: () {
          setState(() {
            if (selectedMenu == MenuSelection.strokeWidth) {
              displayMenu = !displayMenu;
            } else {
              displayMenu = true;
            }
            selectedMenu = MenuSelection.strokeWidth;
          });
        });
  }

  IconButton createColorsWidget() {
    return IconButton(
        icon: const Icon(Icons.color_lens_outlined),
        onPressed: () {
          setState(() {
            if (selectedMenu == MenuSelection.brushColor) {
              displayMenu = !displayMenu;
            } else {
              displayMenu = true;
            }
            selectedMenu = MenuSelection.brushColor;
          });
        });
  }

  IconButton createSettingsWidget() {
    return IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          setState(() {
            if (selectedMenu == MenuSelection.settingMenu) {
              displayMenu = !displayMenu;
            } else {
              displayMenu = true;
            }
            selectedMenu = MenuSelection.settingMenu;
          });
        });
  }

  getColoredCircleList() {
    return [createColoredCircle(Colors.red), createColoredCircle(Colors.green), createColoredCircle(Colors.blue)];
  }

  getWidthCircleList() {
    return [createWidthCircle(3, 16, 16), createWidthCircle(8, 20, 20), createWidthCircle(13, 24, 24)];
  }

  getSettingsList() {
    return [
      createSettingOption(const Icon(Icons.undo_outlined)),
      createSettingOption(const Icon(Icons.restart_alt_outlined)),
      createSettingOption(const Icon(Icons.upload_file_outlined))
    ];
  }

  Widget createColoredCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          displayMenu = false;
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          height: 24,
          width: 24,
          color: color,
        ),
      ),
    );
  }

  Widget createWidthCircle(double newStrokeWidth, double height, double width) {
    return GestureDetector(
      onTap: () {
        setState(() {
          displayMenu = false;
          strokeWidth = newStrokeWidth;
        });
      },
      child: ClipOval(
        child: Container(
          height: height,
          width: width,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget createSettingOption(Icon selctedSetting) {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (selctedSetting.icon == Icons.restart_alt_outlined) {
              restartHandler();
            }
            if (selctedSetting.icon == Icons.undo_outlined) {
              undoHandler();
            }
            if (selctedSetting.icon == Icons.upload_file_outlined) {
              uploadHandler();
            }
          });
        },
        child: selctedSetting);
  }

  void restartHandler() {
    selectedColor = Colors.red;
    strokeWidth = 3.0;
    selectedMenu = MenuSelection.strokeWidth;
    points.clear();
    robotMoves.clear();
    bresenhamPoints.clear();
    scaledPoints.clear();
    displayMenu = false;
  }

  void undoHandler() {
    getRobotMovesFromBresenham(getBresenhamPoints(5, 1, 5, 18));
    if (points.isNotEmpty) {
      points.removeLast();
    }
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].pointLocation == dummyPoint) {
        break;
      }
      points.removeLast();
    }
    if (points.isEmpty) {
      displayMenu = false;
    }
  }

  void uploadHandler() {
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
      bresenhamPoints += getBresenhamPoints(cur.dx.round(), cur.dy.round(), next.dx.round(), next.dy.round());
    }
    robotMoves = getRobotMovesFromBresenham(bresenhamPoints);
    displayMenu = false;
    DatabaseReference pointsRef = FirebaseDatabase.instance.ref("Points");
    for (var move in robotMoves) {
      DatabaseReference curPoint = pointsRef.push();
      curPoint.set(move.toString());
    }
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({required this.pointsList});
  List<DrawingPoint> pointsList;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      var curLocation = pointsList[i].pointLocation;
      var nextLocation = pointsList[i + 1].pointLocation;

      if (curLocation != dummyPoint && nextLocation != dummyPoint) {
        canvas.drawLine(curLocation, nextLocation, pointsList[i].paint);
      } else if (curLocation != dummyPoint && nextLocation == dummyPoint) {
        canvas.drawPoints(
            PointMode.points, [curLocation, Offset(curLocation.dx + 0.1, curLocation.dy + 0.1)], pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class DrawingPoint {
  Paint paint;
  Offset pointLocation;
  DrawingPoint({required this.pointLocation, required this.paint});

  void printPoint() {
    debugPrint(pointLocation.dx.round().toString() +
        "  " +
        pointLocation.dy.round().toString() +
        "  " +
        paint.color.toString());
  }
}

enum MenuSelection { strokeWidth, brushColor, settingMenu }
