// @dart = 2.9
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

List<CameraDescription> cameras = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'KumChat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          accentColor: Color(0xFFFEF9EB),
          backgroundColor: Colors.white30,
          canvasColor: Colors.transparent,
        ),
        home: Intermediary()
        //new RootPage(auth: new Auth(),cameras:cameras)

        );
  }
}

class Intermediary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (snapshot.hasData &&
              (snapshot.data.getString(PHONE) == null ||
                  snapshot.data.getString(PHONE).isEmpty)) {
            return MaterialApp(
                home:
                    LoginScreen(title: 'Sign in to KumChat', cameras: cameras));
          } else if (snapshot.hasData &&
              snapshot.data.getString(PHONE) != null) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: HomeScreen(
                  phone: snapshot.data.getString(PHONE),
                  cameras: cameras,
                  userId: snapshot.data.getString(ID),
                  countryCode: snapshot.data.getString(COUNTRY_CODE),
                ));
          }
          return MaterialApp(
              home: Container(
            child: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
            ),
            color: Colors.blue,
          ));
        });
  }
}
