import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  Color? curColor = Colors.red;
  double? curWidth = 0;
  Settings? curSetting = Settings.undo;
  double posx = 100.0;
  double posy = 100.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
          title: const Text("PaintBot", style: TextStyle(color: Colors.blueGrey)),
          elevation: 2,
          backgroundColor: const Color.fromRGBO(255, 215, 0, 100),
          actions: <Widget>[
            ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<Icon>(
                  icon: const Icon(Icons.color_lens_outlined),
                  dropdownColor: Colors.transparent,
                  onChanged: (Icon? newColor) {
                    setState(() {
                      curColor = newColor?.color;
                      debugPrint(curColor.toString());
                    });
                  },
                  items: <Icon>[
                    const Icon(Icons.circle, color: Colors.red),
                    const Icon(Icons.circle, color: Colors.green),
                    const Icon(Icons.circle, color: Colors.blue)
                  ].map<DropdownMenuItem<Icon>>((Icon color) {
                    return DropdownMenuItem<Icon>(
                      value: color,
                      child: Container(
                          padding: EdgeInsets.only(left: 20),
                          margin: EdgeInsets.only(left: 0, top: 55),
                          child: color),
                    );
                  }).toList(),
                )),
            ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<Icon>(
                  icon: const Icon(Icons.line_weight),
                  dropdownColor: Colors.transparent,
                  onChanged: (Icon? newWidth) {
                    setState(() {
                      curWidth = newWidth?.size;
                      debugPrint(curWidth.toString());
                    });
                  },
                  items: <Icon>[
                    const Icon(
                      Icons.circle,
                      color: Colors.black,
                      size: 20,
                    ),
                    const Icon(
                      Icons.circle,
                      color: Colors.black,
                      size: 25,
                    ),
                    const Icon(
                      Icons.circle,
                      color: Colors.black,
                      size: 30,
                    )
                  ].map<DropdownMenuItem<Icon>>((Icon line) {
                    return DropdownMenuItem<Icon>(
                      value: line,
                      child: Center(child: line),
                    );
                  }).toList(),
                )),
            Container(
                margin: const EdgeInsets.only(right: 70),
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<Icon>(
                    icon: const Icon(Icons.settings),
                    dropdownColor: Colors.transparent,
                    onChanged: (Icon? newSetting) {
                      setState(() {
                        if (newSetting?.icon == Icons.undo_outlined) curSetting = Settings.undo;
                        if (newSetting?.icon == Icons.restart_alt_outlined)
                          curSetting = Settings.newFile;
                        if (newSetting?.icon == Icons.upload_file_outlined)
                          curSetting = Settings.upload;
                        debugPrint(curSetting.toString());
                      });
                    },
                    items: <Icon>[
                      const Icon(Icons.undo_outlined, color: Colors.black),
                      const Icon(Icons.restart_alt_outlined, color: Colors.black),
                      const Icon(Icons.upload_file_outlined, color: Colors.black)
                    ].map<DropdownMenuItem<Icon>>((Icon setting) {
                      return DropdownMenuItem<Icon>(
                        value: setting,
                        child: Center(child: setting),
                      );
                    }).toList(),
                  ),
                ))
          ]),
      body: GestureDetector(
          onTapDown: (TapDownDetails details) => onTapDown(context, details),
          child: Stack(fit: StackFit.expand, children: <Widget>[
            Container(color: Colors.white),
            Positioned(
              child: Text(''),
              left: posx,
              top: posy,
            )
          ])),
      backgroundColor: Colors.white,
    ));
  }

  void onTapDown(BuildContext context, TapDownDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;
    // or user the local position method to get the offset
    print(details.localPosition);
    print("tap down " + x.toString() + ", " + y.toString());
    MyCustomPainter painter;
  }
}

class MyCustomPainter extends CustomPainter {
  // 2
  @override
  void paint(Canvas canvas, Size size) {
    Offset startPoint = Offset(0, 0);
    Offset endPoint = Offset(size.width, size.height);
    Paint paint = Paint();
    canvas.drawLine(startPoint, endPoint, paint);
  }

  // 4
  @override
  bool shouldRepaint(MyCustomPainter delegate) {
    return true;
  }
}

enum Settings { undo, newFile, upload }
