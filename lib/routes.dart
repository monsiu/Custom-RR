// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:android/home.dart';

import 'package:android/custom_roms.dart';
import 'package:android/custom_rec.dart';
import 'package:android/instructions.dart';

class RouteManager {
  static const String homePage = '/';
  static const String secondPage = '/customroms';
  static const String thirdPage = '/customrecs';
  static const String fourthPage = '/instructions';
 

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homePage:
        return MaterialPageRoute(
          builder: (context) => HomePage(),
        );
      case secondPage:
        return MaterialPageRoute(
          builder: (context) => CustomromsPage(),
        );
      case thirdPage:
        return MaterialPageRoute(
          
          builder: (context) => CustomrecPage(),
        );
      case fourthPage:
        return MaterialPageRoute(
          builder: (context) => InstructionsPage(),
        );
      
      default:
        throw FormatException('Route Not Found! Check Routes Again!');
    }
  }
}
