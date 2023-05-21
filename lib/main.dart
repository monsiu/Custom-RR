// ignore_for_file: prefer_const_constructors, unused_import, depend_on_referenced_packages
import 'package:custom_rr/home.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:custom_rr/routes.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:page_transition/page_transition.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    //color set to transperent or set your own color
    systemNavigationBarIconBrightness: Brightness
        .light, //set brightness for icons, like dark background light icons
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarDividerColor: Colors.green,
  ));

//Setting SystmeUIMode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top]);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSplashScreen(
          splash: Image.asset(
            'images/splashanipic.png',
          ),
          duration: 3000,
          splashIconSize: double.infinity,
          splashTransition: SplashTransition.fadeTransition,
          pageTransitionType: PageTransitionType.fade,
          backgroundColor: Colors.grey,
          centered: true,
          nextScreen: HomePage()),
      initialRoute: RouteManager.homePage,
      onGenerateRoute: RouteManager.generateRoute,
    );
  }
}
