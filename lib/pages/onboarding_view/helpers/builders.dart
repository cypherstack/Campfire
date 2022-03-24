import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';

buildOnboardingAppBar(BuildContext context,
    {VoidCallback backButtonPressed, List<Widget> actions}) {
  return AppBar(
    backgroundColor: CFColors.starryNight,
    toolbarHeight: SizingUtilities.onboardingToolBarHeight,
    title: Image(
      image: AssetImage(
        "assets/images/logo.png",
      ),
      height: 55,
    ),
    // leadingWidth: 56,
    leading: Padding(
      padding: EdgeInsets.only(
        top: 22,
        bottom: 22,
        left: 20,
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: AppBarIconButton(
          shadows: [],
          color: Color(0xFF51566E).withOpacity(0.3),
          size: 36,
          onPressed: backButtonPressed == null
              ? () {
                  Logger.print("leading appbar button pressed");
                  Navigator.pop(context);
                }
              : backButtonPressed,
          circularBorderRadius: 8,
          icon: SvgPicture.asset(
            "assets/svg/chevronLeft.svg",
            color: CFColors.twilight,
            width: 24,
            height: 24,
          ),
        ),
      ),
    ),
    actions: actions,
  );
}

buildOnboardingBody(BuildContext context, Widget child) {
  return Material(
    color: CFColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(SizingUtilities.circularBorderRadius * 2),
        topRight: Radius.circular(SizingUtilities.circularBorderRadius * 2),
      ),
    ),
    child: child,
  );
}
