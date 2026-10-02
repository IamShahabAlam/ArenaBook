import 'package:flutter/material.dart';

class AppBoxShadow {
  static const btnBoxShadow = BoxShadow(
    color: Colors.transparent,
    spreadRadius: 2.0,
    blurRadius: 4.0,
    offset: Offset(1, 2),
  );

  static const tinyBtnBoxShadow = BoxShadow(
    color: Colors.transparent,
    spreadRadius: 0.2,
    blurRadius: 5,
    offset: Offset(1, 3),
  );

  static const textfieldBoxShadow = BoxShadow(
    color: Colors.transparent,
    spreadRadius: 0.2,
    blurRadius: 5,
    offset: Offset(3, 3),
  );
  static const appBarBoxShadow = BoxShadow(
    color: Colors.transparent,
    spreadRadius: 0.2,
    blurRadius: 5,
    offset: Offset(3, 3),
  );

  static const containerLightShadow = BoxShadow(
    color: Color.fromARGB(165, 207, 207, 207),
    spreadRadius: 0.2,
    blurRadius: 5,
    offset: Offset(3, 3),
  );
}
