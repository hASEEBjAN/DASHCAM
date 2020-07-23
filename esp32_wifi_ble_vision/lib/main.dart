import 'package:flutter/material.dart';
import 'screens/wifi_list.dart';
import 'package:advanced_splashscreen/advanced_splashscreen.dart';
void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP CAMERA STREAMER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AdvancedSplashScreen(
        child: WifiList(),
        seconds: 3,
        colorList: [Color(0xff0088e2), Color(0xff0075cd), Color(0xff0063b8)],
        appTitle: "Dash Cam",
        appIcon: "images/dashcam_white.png",
      ),
    );
  }
}
