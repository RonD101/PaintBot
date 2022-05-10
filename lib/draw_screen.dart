import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'bresenham_algo.dart';

// 8cm/1000 = 8 * 10^-5 meters/tick left/right/up/down.
const Offset dummyOffset = Offset(-1, -1);
enum MenuSelection { strokeWidth, brushColor, settingMenu }
enum UploadFlag { readyForPulse, readingPulse, startDraw, reuploadLast, sendNumOfMoves }
enum PointType { regular, dummyUp, dummyDown }

class DrawerScreen extends StatefulWidget {
  final double width;
  final double height;
  const DrawerScreen({Key? key, required this.width, required this.height}) : super(key: key);
  @override
  DrawState createState() => DrawState();
}

class DrawState extends State<DrawerScreen> {
  Color selectedColor = Colors.red;
  double strokeWidth = 3.0;
  List<DrawingPoint> points = [];
  bool displayMenu = false;
  double opacity = 1.0;
  MenuSelection selectedMenu = MenuSelection.strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                padding: const EdgeInsets.only(left: 60.0, right: 60.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: const Color.fromRGBO(255, 215, 0, 1)),
                child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[createStrokeWidget(), createColorsWidget(), createSettingsWidget()]),
                      createMenuWidget()
                    ])))),
        body: drawUserInput(context));
  }

  GestureDetector drawUserInput(BuildContext context) {
    return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(DrawingPoint(
                pointType: PointType.regular,
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
                pointType: PointType.dummyDown,
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
            points.add(DrawingPoint(pointType: PointType.dummyUp, pointLocation: dummyOffset, paint: Paint()));
          });
        },
        child: CustomPaint(size: Size.infinite, painter: DrawingPainter(pointsList: points)));
  }

  AnimatedOpacity createMenuWidget() {
    return AnimatedOpacity(
        opacity: displayMenu ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        child: Visibility(child: selectCurrentMenu(), visible: displayMenu));
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
        child: ClipOval(child: Container(height: 24, width: 24, color: color)));
  }

  Widget createWidthCircle(double newStrokeWidth, double height, double width) {
    return GestureDetector(
        onTap: () {
          setState(() {
            displayMenu = false;
            strokeWidth = newStrokeWidth;
          });
        },
        child: ClipOval(child: Container(height: height, width: width, color: Colors.black)));
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
    displayMenu = false;
    FirebaseDatabase.instance.ref("RobotMoves").remove();
    FirebaseDatabase.instance.ref("NumOfMoves").remove();
    FirebaseDatabase.instance.ref("Flag").remove();
  }

  void undoHandler() {
    if (points.isNotEmpty) {
      points.removeLast();
    }
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].pointLocation == dummyOffset) {
        break;
      }
      points.removeLast();
    }
    if (points.isEmpty) {
      displayMenu = false;
    }
  }

  void uploadHandler() async {
    var bresenhamPoints = globalBresenhamAlgo(points, widget.width, widget.height);
    var robotMoves = getRobotMovesFromBresenham(bresenhamPoints);
    for (DrawingPoint p in bresenhamPoints) {
      p.printPoint();
    }
    for (RobotMove m in robotMoves) {
      debugPrint(m.toString() + "\n");
    }
    // startUploading(robotMoves);
    displayMenu = false;
  }

  Future<void> startUploading(List<RobotMove> robotMoves) async {
    const int uploadCapacity = 1000;
    final DatabaseReference movesRef = FirebaseDatabase.instance.ref("RobotMoves");
    final DatabaseReference flagRef = FirebaseDatabase.instance.ref("Flag");
    final int numOfMoves = robotMoves.length;
    FirebaseDatabase.instance.ref("NumOfMoves").set(numOfMoves);
    movesRef.remove();
    flagRef.set(UploadFlag.sendNumOfMoves.index);
    var flagVal = await flagRef.get();
    while (flagVal.value != UploadFlag.readyForPulse.index) {
      flagVal = await flagRef.get();
    }
    int numOfUploads = numOfMoves ~/ uploadCapacity;
    if (numOfMoves % uploadCapacity != 0) {
      numOfUploads++;
    }
    for (int curUpload = 0; curUpload <= numOfUploads; curUpload++) {
      flagVal = await flagRef.get();
      while (flagVal.value == UploadFlag.readingPulse.index) {
        flagVal = await flagRef.get();
      }
      if (flagVal.value == UploadFlag.reuploadLast.index) {
        if (curUpload > 0) {
          curUpload--;
        }
      }
      if (curUpload == numOfUploads) {
        flagRef.set(UploadFlag.startDraw.index);
        return;
      }
      movesRef.remove();
      int curNumOfMoves = uploadCapacity;
      if (curUpload == numOfUploads - 1 && (numOfMoves % uploadCapacity != 0)) {
        curNumOfMoves = numOfMoves % uploadCapacity;
      }
      for (int i = 0; i < curNumOfMoves; i++) {
        final int curMoveIndex = i + uploadCapacity * curUpload;
        movesRef.child(i.toString()).set(robotMoves[curMoveIndex].index);
      }
      flagRef.set(UploadFlag.readingPulse.index);
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

      if (curLocation != dummyOffset && nextLocation != dummyOffset) {
        canvas.drawLine(curLocation, nextLocation, pointsList[i].paint);
      } else if (curLocation != dummyOffset && nextLocation == dummyOffset) {
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
  PointType pointType;
  DrawingPoint({required this.pointLocation, required this.paint, required this.pointType});

  void printPoint() {
    debugPrint(pointLocation.dx.round().toString() +
        "  " +
        pointLocation.dy.round().toString() +
        "  " +
        pointType.toString());
  }
}
