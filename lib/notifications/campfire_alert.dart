import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';

class CampfireAlert extends StatelessWidget {
  const CampfireAlert({Key key, @required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ModalPopupDialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 28,
              left: 24,
              right: 24,
              bottom: 12,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(
            height: SizingUtilities.standardPadding,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(SizingUtilities.standardPadding),
              child: SizedBox(
                height: SizingUtilities.standardButtonHeight,
                width: SizingUtilities.standardFixedButtonWidth,
                child: GradientButton(
                  key: Key("campfireAlertOKButtonKey"),
                  child: FittedBox(
                    child: Text(
                      "OK",
                      style: CFTextStyles.button,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
