import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_world/home.dart';
import 'package:real_world/my_colors.dart';
import 'package:real_world/my_strings.dart';

void main() async {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Strings.appName,
      theme: new ThemeData(
          primaryColor: MyColors.colorPrimary,
          accentColor: MyColors.accentColor,
          fontFamily: Strings.customFont),
      home: new Home()));
}
