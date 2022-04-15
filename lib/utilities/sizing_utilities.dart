import 'package:flutter/material.dart';

abstract class SizingUtilities {
  static const double circularBorderRadius = 10.0;
  static const double checkboxBorderRadius = 4.0;

  static const double listItemSpacing = 8.0;

  static const double standardPadding = 20.0;

  static const double standardButtonHeight = 48.0;
  static const double standardFixedButtonWidth = 204.0;

  static const double bottomToolBarHeight = 77.0;
  static const double onboardingToolBarHeight = 80.0;

  static double getAppBarHeight(AppBar appBar) =>
      appBar?.preferredSize?.height ?? kToolbarHeight;

  static double getStatusBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double getBodyHeight(BuildContext context) =>
      MediaQuery.of(context).size.height -
      getStatusBarHeight(context) -
      getAppBarHeight(null);

  // Layout determination based on screen width
  static bool isTinyWidth(BuildContext context) =>
      MediaQuery.of(context).size.width < 350;
}
