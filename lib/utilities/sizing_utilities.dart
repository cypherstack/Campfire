import 'package:flutter/material.dart';

class SizingUtilities {
  static const double circularBorderRadius = 10.0;
  static const double checkboxBorderRadius = 4.0;

  static const double listItemSpacing = 8.0;

  static const double standardPadding = 20.0;

  static const double standardButtonHeight = 48.0;

  static const double bottomToolBarHeight = 77.0;

  static double getAppBarHeight(AppBar appBar) {
    if (appBar != null) {
      return appBar.preferredSize.height;
    }
    return kToolbarHeight;
  }

  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getBodyHeight(BuildContext context) {
    return MediaQuery.of(context).size.height -
        getStatusBarHeight(context) -
        getAppBarHeight(null);
  }
}
