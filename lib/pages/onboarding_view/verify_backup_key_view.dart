import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/helpers/builders.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:provider/provider.dart';

class VerifyBackupKeyView extends StatefulWidget {
  const VerifyBackupKeyView({Key key}) : super(key: key);

  @override
  _VerifyBackupKeyViewState createState() => _VerifyBackupKeyViewState();
}

class _VerifyBackupKeyViewState extends State<VerifyBackupKeyView> {
  final _textEditController = TextEditingController();

  Future<List<String>> _getMnemonic(BuildContext context) async {
    final manager = Provider.of<Manager>(context, listen: false);
    final mnemonic = await manager.mnemonic;
    return mnemonic;
  }

  Future<bool> _verifyMnemonicContains(
      BuildContext context, String word, int position) async {
    final list = await _getMnemonic(context);
    return list[position] == word;
  }

  final int _randomPosition = Random().nextInt(12);

  final _positionStrings = [
    "1st",
    "2nd",
    "3rd",
    "4th",
    "5th",
    "6th",
    "7th",
    "8th",
    "9th",
    "10th",
    "11th",
    "12th"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.starryNight,
      appBar: buildOnboardingAppBar(context),
      body: buildOnboardingBody(
        context,
        Column(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  FittedBox(
                    child: Text(
                      "Backup Key Verification",
                      style: CFTextStyles.pinkHeader,
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  FittedBox(
                    child: Text(
                      "Type the ${_positionStrings[_randomPosition]} word from your key.",
                      style: GoogleFonts.workSans(
                        color: CFColors.dusk,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _textEditController,
                      decoration: InputDecoration(hintText: "Type here..."),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            SizedBox(
              height: 48,
              width: MediaQuery.of(context).size.width -
                  (SizingUtilities.standardPadding * 2),
              child: GradientButton(
                child: FittedBox(
                  child: Text(
                    "CONFIRM",
                    style: GoogleFonts.workSans(
                      color: CFColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                onTap: () async {
                  // check if field contains correct word
                  final success = await _verifyMnemonicContains(
                      context, _textEditController.text, _randomPosition);
                  if (success) {
                    FocusScope.of(context).unfocus();

                    OverlayNotification.showSuccess(
                      context,
                      "Correct! Your wallet is set up.",
                      Duration(milliseconds: 1500),
                    );
                    await Future.delayed(Duration(milliseconds: 200));

                    Navigator.pushReplacementNamed(context, "/mainview");
                  } else {
                    OverlayNotification.showError(
                      context,
                      "Incorrect. Please try again.",
                      Duration(milliseconds: 1500),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
