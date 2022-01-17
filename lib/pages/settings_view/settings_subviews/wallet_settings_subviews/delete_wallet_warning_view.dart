import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_subviews/wallet_delete_mnemonic_view.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';

class DeleteWalletWarningView extends StatelessWidget {
  const DeleteWalletWarningView({Key key}) : super(key: key);

  // final _textStyle = GoogleFonts.workSans();
  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width -
        (SizingUtilities.standardPadding * 2);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, ""),
      body: Padding(
        padding: EdgeInsets.all(SizingUtilities.standardPadding),
        child: Column(
          children: [
            SizedBox(
              height: 9,
            ),
            Text(
              "Warning!",
              style: CFTextStyles.pinkHeader,
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            _buildWarningText(),
            Spacer(),
            SizedBox(
              height: 10,
            ),
            _buildCancelButton(buttonWidth, context),
            SizedBox(
              height: 12,
            ),
            _buildContinueButton(buttonWidth, context),
          ],
        ),
      ),
    );
  }

  _buildWarningText() {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        border: Border.all(
          width: 1,
          color: CFColors.smoke,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: SizingUtilities.standardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You are going to permanently delete you wallet.",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            Text(
              "If you delete your wallet, the only way you can have access to your funds is by using your backup key.",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            Text(
              "Campfire Wallet does not keep nor is able to restore your backup key or your wallet.",
              style: GoogleFonts.workSans(
                color: CFColors.dusk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            Text(
              "PLEASE SAVE YOUR BACKUP KEY.",
              style: GoogleFonts.workSans(
                color: CFColors.spark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildCancelButton(double width, BuildContext context) {
    return SizedBox(
      height: SizingUtilities.standardButtonHeight,
      width: width,
      child: SimpleButton(
        child: FittedBox(
          child: Text(
            "CANCEL AND GO BACK",
            style: CFTextStyles.button.copyWith(
              color: CFColors.dusk,
            ),
          ),
        ),
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.pop();
        },
      ),
    );
  }

  _buildContinueButton(double width, BuildContext context) {
    return SizedBox(
      height: SizingUtilities.standardButtonHeight,
      width: width,
      child: GradientButton(
        child: FittedBox(
          child: Text(
            "VIEW BACKUP KEY",
            style: CFTextStyles.button,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => WalletDeleteMnemonicView()),
          );
        },
      ),
    );
  }
}
