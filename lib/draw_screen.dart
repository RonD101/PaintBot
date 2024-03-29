import 'package:flutter/material.dart';
import 'bresenham_algo.dart';
import 'upload_handler.dart';
import 'app_utils.dart';
import 'robot_test.dart';

class DrawerScreen extends StatefulWidget {
  final double width;
  final double height;
  final double statusBar;
  late final ScaleData scaleData;
  DrawerScreen({Key? key, required this.width, required this.height, required this.statusBar}) : super(key: key) {
    scaleData = ScaleData(width, height, statusBar);
  }
  @override
  DrawState createState() => DrawState();
}

class DrawState extends State<DrawerScreen> {
  MenuSelection selectedMenu = MenuSelection.brushColor;
  List<DrawingPoint> points  = [];
  Color selectedColor        = Colors.red;
  bool displayMenu           = false;
  double strokeWidth         = lightWidth;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                padding: const EdgeInsets.only(left: 60.0, right: 60.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), color: const Color.fromRGBO(170, 169, 173, 1)),
                child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                        createStrokeWidget(),
                        createColorsWidget(),
                        createTestWidget(),
                        createSettingsWidget()
                      ]),
                      Visibility(child: selectCurrentMenu(), visible: displayMenu)
                    ])))),
        body: drawUserInput(context));
  }

  GestureDetector drawUserInput(BuildContext context) {
    return GestureDetector(
        // User adds more points
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(DrawingPoint(
                type: PointType.regular,
                location: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = StrokeCap.round
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
                strokeWidth: strokeWidth));
          });
        },
        // First touch of user
        onPanStart: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(DrawingPoint(
                type: PointType.dummyDown,
                location: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = StrokeCap.round
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
                strokeWidth: strokeWidth));
          });
        },
        // User lifts finger from screen after finishing a single line.
        onPanEnd: (details) {
          setState(() {
            points.add(upPoint);
          });
        },
        child: CustomPaint(size: Size.infinite, painter: DrawingPainter(pointList: points)));
  }

  // Widgets for menu bar.
  Row selectCurrentMenu() {
    if (selectedMenu == MenuSelection.strokeWidth) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getWidthCircleList());
    }
    if (selectedMenu == MenuSelection.brushColor) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getColoredCircleList());
    }
    if (selectedMenu == MenuSelection.testMenu) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getTestList());
    }
    if (selectedMenu == MenuSelection.settingMenu) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: getSettingsList());
    }
    throw Exception("Invalid menu selected");
  }

  IconButton createStrokeWidget() {
    return IconButton(
        icon: const Icon(BotIcons.stroke),
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
        icon: const Icon(BotIcons.color),
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
        icon: const Icon(BotIcons.settings),
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

  IconButton createTestWidget() {
    return IconButton(
        icon: const Icon(BotIcons.test),
        onPressed: () {
          setState(() {
            if (selectedMenu == MenuSelection.testMenu) {
              displayMenu = !displayMenu;
            } else {
              displayMenu = true;
            }
            selectedMenu = MenuSelection.testMenu;
          });
        });
  }

  List<Widget> getColoredCircleList() {
    return [
      createColoredCircle(Colors.yellow), 
      createColoredCircle(Colors.orange), 
      createColoredCircle(Colors.red),
      createColoredCircle(Colors.purple), 
      createColoredCircle(Colors.brown), 
      createColoredCircle(Colors.black),
      createColoredCircle(Colors.lightGreen), 
      createColoredCircle(Colors.green), 
      createColoredCircle(Colors.lightBlue),
      createColoredCircle(Colors.blue), 
      createColoredCircle(Colors.pink), 
      createColoredCircle(Colors.white)
    ];
  }

  List<Widget> getWidthCircleList() {
    return [
      createWidthCircle(lightWidth, 16, 16), 
      createWidthCircle(thickWidth, 24, 24)
    ];
  }

  List<Widget> getSettingsList() {
    return [
      createSettingOption(BotIcons.undo),
      createSettingOption(BotIcons.restart),
      createSettingOption(BotIcons.upload)
    ];
  }

  List<Widget> getTestList() {
    return [
      createTestOption(BotIcons.calibration), 
      createTestOption(BotIcons.square),
      createTestOption(BotIcons.rightUp), 
      createTestOption(BotIcons.goHome)
    ];
  }

  Widget createColoredCircle(Color color) {
    return GestureDetector(
        onTap: () {
          setState(() {
            displayMenu   = false;
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

  Widget createSettingOption(IconData selctedSetting) {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (selctedSetting == BotIcons.restart) {
              restartHandler();
            } else if (selctedSetting == BotIcons.undo) {
              undoHandler();
            } else if (selctedSetting == BotIcons.upload) {
              uploadHandler();
            }
          });
        },
        child: Icon(selctedSetting));
  }

  Widget createTestOption(IconData selectedTest) {
    return GestureDetector(
        onTap: () {
          setState(() {
            displayMenu = false;
            if (selectedTest == BotIcons.square) {
              squareTest(widget.scaleData);
            } else if (selectedTest == BotIcons.rightUp) {
              upRightTest(widget.scaleData);
            } else if (selectedTest == BotIcons.goHome) {
              goHomeTest();
            } else if (selectedTest == BotIcons.calibration) {
              calibrationTest();
            }
          });
        },
        child: Icon(selectedTest));
  }

  void restartHandler() async {
    selectedColor = Colors.red;
    strokeWidth   = lightWidth;
    selectedMenu  = MenuSelection.strokeWidth;
    displayMenu   = false;
    // Set firebase to initial state.
    points.clear();
    await movesRef.remove();
    await numOfMovesRef.remove();
    await flagRef.set(UploadFlag.readyForPulse.index);
  }

  // Remove a single line from draw (line - all points between finger down and finger up)
  void undoHandler() async {
    if (points.isNotEmpty) {
      points.removeLast();
    }
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].location == dummyOffset) {
        break;
      }
      points.removeLast();
    }
    if (points.isEmpty) {
      displayMenu = false;
    }
  }

  // Upload draw to firebase. Include the entire chain the points must go through before they go to firebase.
  void uploadHandler() async {
    displayMenu = false;
    if (points.length <= 3) {
      restartHandler();
      return;
    }
    final List<DrawingPoint> scaledPoints     = getScaledPoints(points, widget.scaleData);
    final List<DrawingPoint> pointsWithColors = getPointsWithColors(scaledPoints);
    final List<DrawingPoint> smoothPoints     = getSmoothPoints(pointsWithColors);
    final List<DrawingPoint> bresenhamPoints  = globalBresenham(smoothPoints);
    final List<RobotMove>    robotMoves       = getRobotMoves(bresenhamPoints);
    final List<CompMove>     compressedMoves  = getCompressedMoves(robotMoves);
    await startUploading(compressedMoves);
  }
}
