import 'draw_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const PaintBotApp());

class PaintBotApp extends StatelessWidget {
  const PaintBotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DrawerScreen(),
    );
  }
}
