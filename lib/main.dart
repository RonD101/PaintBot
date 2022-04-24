import 'draw_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PaintBotApp());
}

class PaintBotApp extends StatelessWidget {
  final Future<FirebaseApp>? _fbApp = Firebase.initializeApp();
  PaintBotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MediaQuery(
        data: const MediaQueryData(),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: FutureBuilder(
              future: _fbApp,
              builder: (context, snapshot) {
                double width = MediaQuery.of(context).size.width;
                double height = MediaQuery.of(context).size.height;
                if (snapshot.hasError) {
                  return const Text("Something is wrong");
                } else if (snapshot.hasData) {
                  return DrawerScreen(height: height, width: width);
                } else {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Color.fromRGBO(255, 215, 0, 1),
                    backgroundColor: Colors.white,
                  ));
                }
              },
            )));
  }
}
