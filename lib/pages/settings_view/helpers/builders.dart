import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';

AppBar buildSettingsAppBar(BuildContext context, String title,
    {Widget rightButton,
    bool disableBackButton,
    VoidCallback onBackPressed,
    bool backDelayed = true}) {
  final List<Widget> actions = rightButton == null ? [] : [rightButton];

  bool _disableBackButton =
      disableBackButton == null ? false : disableBackButton;

  final TextStyle _titleStyle = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  return AppBar(
    backgroundColor: CFColors.white,
    title: Text(
      title,
      style: _titleStyle,
    ),

    actions: actions,

    // leading appbar button
    leadingWidth:
        _disableBackButton ? null : 36.0 + 20.0, // account for 20 padding

    leading: _disableBackButton
        ? null
        : Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 20,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                key: Key("settingsAppBarBackButton"),
                size: 36,
                onPressed: () async {
                  if (backDelayed) {
                    FocusScope.of(context).unfocus();
                    await Future.delayed(Duration(milliseconds: 50));
                  }
                  if (onBackPressed != null) onBackPressed();
                  Navigator.pop(context);
                },
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
  );
}
