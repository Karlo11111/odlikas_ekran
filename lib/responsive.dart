import 'package:flutter/material.dart';

class Responsive {
  double scaleWidth(BuildContext context, double size) {
  return MediaQuery.of(context).size.width * (size / 375.0);
}

double scaleHeight(BuildContext context, double size) {
  return MediaQuery.of(context).size.height * (size / 812.0);
}
}