import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/create_pin_view.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:provider/provider.dart';

import 'helpers/builders.dart';
import 'helpers/create_wallet_type.dart';

class NameYourWalletView extends StatefulWidget {
  const NameYourWalletView({Key key, @required this.type}) : super(key: key);

  final CreateWalletType type;

  @override
  _NameYourWalletViewState createState() => _NameYourWalletViewState();
}

class _NameYourWalletViewState extends State<NameYourWalletView> {
  final _nameTextEditingController = TextEditingController();

  final _focusNode = FocusNode();

  final _words = [
    "Amber",
    "Ash",
    "Blaze",
    "Gleam",
    "Glow",
    "Log",
    "Marshmallow",
    "Spark",
    "Stargaze",
  ];

  bool _showTextField;

  @override
  Widget build(BuildContext context) {
    final WalletsService walletsService = Provider.of<WalletsService>(context);

    return Scaffold(
      backgroundColor: CFColors.starryNight,
      appBar: buildOnboardingAppBar(context),
      body: buildOnboardingBody(
        context,
        Column(
          children: [
            SizedBox(
              height: 40,
            ),
            FittedBox(
              child: Text(
                "Name your wallet",
                style: CFTextStyles.pinkHeader,
              ),
            ),
            SizedBox(
              height: 12,
            ),
            FittedBox(
              child: Text(
                "Use your own label",
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                "or choose one of our suggestions.",
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 7,
              ),
              child: TextField(
                controller: _nameTextEditingController,
                focusNode: _focusNode,
                style: CFTextStyles.textField,
                decoration: InputDecoration(
                  hintText: "Enter wallet name",
                  hintStyle: CFTextStyles.textFieldHint,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 7,
              ),
              child: _buildDropdown(),
            ),
            if (_focusNode.hasFocus)
              SizedBox(
                height: 7,
              ),
            Spacer(),
            SizedBox(
              height: 48,
              width: MediaQuery.of(context).size.width -
                  (SizingUtilities.standardPadding * 2),
              child: GradientButton(
                onTap: () {
                  final walletName = _nameTextEditingController.text;
                  if (walletName.isEmpty) {
                    OverlayNotification.showError(
                      context,
                      "Please name your wallet",
                      Duration(seconds: 2),
                    );
                  } else {
                    // check if wallet name is already in use
                    walletsService.checkForDuplicate(walletName).then(
                      (isInUse) async {
                        if (isInUse) {
                          OverlayNotification.showError(
                            context,
                            "You already have a wallet named: $walletName",
                            Duration(seconds: 2),
                          );
                        } else {
                          FocusScope.of(context).unfocus();
                          // Wait for keyboard to disappear before navigating
                          // to prevent render exception being thrown.
                          // TODO: find a less hacky method of dealing with this
                          await Future.delayed(Duration(milliseconds: 100));

                          // continue setting up wallet
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) {
                                return CreatePinView(
                                    type: widget.type, walletName: walletName);
                              },
                            ),
                          );
                        }
                      },
                    );
                  }
                },
                child: Text(
                  "NEXT",
                  style: CFTextStyles.button,
                ),
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

  _buildDropdown() {
    List<DropdownMenuItem> suggestions = [];

    for (int i = 0; i < _words.length; i++) {
      final item = DropdownMenuItem<String>(
        value: _words[i],
        child: Text(
          _words[i],
          style: GoogleFonts.workSans(
            color: CFColors.dusk,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      );
      suggestions.add(item);
    }
    return Container(
      width: MediaQuery.of(context).size.width -
          (SizingUtilities.standardPadding * 2),
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        border: Border.all(
          color: CFColors.twilight,
          width: 1,
        ),
      ),
      child: DropdownButton(
        hint: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            "Suggestions...",
            style: CFTextStyles.textFieldHint,
          ),
        ),
        iconEnabledColor: CFColors.fog,
        underline: Container(),
        elevation: 2,
        dropdownColor: CFColors.fog,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        items: suggestions,
        onChanged: (value) {
          print(value);
        },
      ),
    );
  }

  // _buildSuggestions() {
  //   List<Widget> suggestions = [];
  //
  //   for (int i = 0; i < _words.length; i++) {
  //     final text = Text(
  //       _words[i],
  //       style: GoogleFonts.workSans(
  //         color: CFColors.dusk,
  //         fontWeight: FontWeight.w400,
  //         fontSize: 16,
  //       ),
  //     );
  //     suggestions.add(text);
  //     if (i < _words.length - 1) {
  //       suggestions.add(
  //         SizedBox(
  //           height: 16,
  //         ),
  //       );
  //     }
  //   }
  //
  //   return Container(
  //     width: MediaQuery.of(context).size.width -
  //         (SizingUtilities.standardPadding * 2),
  //     decoration: BoxDecoration(
  //       color: CFColors.fog,
  //       boxShadow: [CFColors.standardBoxShadow],
  //       borderRadius:
  //           BorderRadius.circular(SizingUtilities.circularBorderRadius),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       child: ListView(
  //         shrinkWrap: true,
  //         children: suggestions,
  //       ),
  //     ),
  //   );
  // }
}
