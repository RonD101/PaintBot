import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class Draw extends StatefulWidget {
  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  Color selectedColor = Colors.red;
  double strokeWidth = 3.0;
  List<DrawingPoints> points = [];
  bool showBottomList = false;
  double opacity = 1.0;
  SelectedMode selectedMode = SelectedMode.StrokeWidth;
  List<Color> colors = [Colors.red, Colors.green, Colors.blue];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            padding: const EdgeInsets.only(left: 60.0, right: 60.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: const Color.fromRGBO(255, 215, 0, 1)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                          icon: const Icon(Icons.line_weight),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.StrokeWidth) {
                                showBottomList = !showBottomList;
                              }
                              selectedMode = SelectedMode.StrokeWidth;
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.color_lens_outlined),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.Color) {
                                showBottomList = !showBottomList;
                              }
                              selectedMode = SelectedMode.Color;
                            });
                          }),
                      IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            setState(() {
                              if (selectedMode == SelectedMode.Settings) {
                                showBottomList = !showBottomList;
                              }
                              selectedMode = SelectedMode.Settings;
                            });
                          })
                    ],
                  ),
                  Visibility(
                    child: (selectedMode == SelectedMode.Color)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: getColorList())
                        : (selectedMode == SelectedMode.StrokeWidth)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: getStrokeList())
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: getSettingList()),
                    visible: showBottomList,
                  ),
                ],
              ),
            )),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            points.add(DrawingPoints(
                location: renderBox.globalToLocal(details.globalPosition),
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
            points.add(DrawingPoints(
                location: renderBox.globalToLocal(details.globalPosition),
                paint: Paint()
                  ..strokeCap = StrokeCap.round
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth));
          });
        },
        onPanEnd: (details) {
          setState(() {
            points.add(DrawingPoints(location: const Offset(-1, -1), paint: Paint()));
            for (var p in points) {
              p.printPoint();
            }
            debugPrint("*****************************");
          });
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: DrawingPainter(
            pointsList: points,
          ),
        ),
      ),
    );
  }

  getColorList() {
    List<Widget> listWidget = [];
    for (Color color in colors) {
      listWidget.add(colorCircle(color));
    }
    return listWidget;
  }

  getStrokeList() {
    return [widthSelector(3, 20, 20), widthSelector(8, 25, 25), widthSelector(13, 30, 30)];
  }

  getSettingList() {
    return [
      settingSelector(const Icon(Icons.undo_outlined)),
      settingSelector(const Icon(Icons.restart_alt_outlined)),
      settingSelector(const Icon(Icons.upload_file_outlined))
    ];
  }

  Widget colorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showBottomList = false;
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          height: 30,
          width: 30,
          color: color,
        ),
      ),
    );
  }

  Widget widthSelector(double newStrokeWidth, double height, double width) {
    return GestureDetector(
      onTap: () {
        setState(() {
          showBottomList = false;
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

  Widget settingSelector(Icon selctedIcon) {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (selctedIcon.icon == Icons.restart_alt_outlined) {
              points.clear();
              showBottomList = false;
            } else if (selctedIcon.icon == Icons.undo_outlined) {
              if (points.isNotEmpty) points.removeLast();
              for (int i = points.length - 1; i >= 0; i--) {
                if (points[i].location == const Offset(-1, -1)) {
                  break;
                }
                points.removeLast();
              }
              if (points.isEmpty) showBottomList = false;
            }
          });
        },
        child: selctedIcon);
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({required this.pointsList});
  List<DrawingPoints> pointsList;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i].location != const Offset(-1, -1) &&
          pointsList[i + 1].location != const Offset(-1, -1)) {
        canvas.drawLine(pointsList[i].location, pointsList[i + 1].location, pointsList[i].paint);
      } else if (pointsList[i].location != const Offset(-1, -1) &&
          pointsList[i + 1].location == const Offset(-1, -1)) {
        canvas.drawPoints(
            PointMode.points,
            [
              pointsList[i].location,
              Offset(pointsList[i].location.dx + 0.1, pointsList[i].location.dy + 0.1)
            ],
            pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class DrawingPoints {
  Paint paint;
  Offset location;
  DrawingPoints({required this.location, required this.paint});

  void printPoint() {
    debugPrint(location.dx.toInt().toString() +
        "  " +
        location.dy.toInt().toString() +
        "  " +
        paint.color.toString());
  }
}

enum SelectedMode { StrokeWidth, Color, Settings }
