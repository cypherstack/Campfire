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
  const NameYourWalletView({
    Key key,
    @required this.type,
    this.allowTestNet = false,
  }) : super(key: key);

  final CreateWalletType type;
  final bool allowTestNet;

  @override
  _NameYourWalletViewState createState() => _NameYourWalletViewState();
}

class _NameYourWalletViewState extends State<NameYourWalletView> {
  final _nameTextEditingController = TextEditingController();

  bool _useTestNet = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.starryNight,
      appBar: buildOnboardingAppBar(context),
      body: buildOnboardingBody(
        context,
        Padding(
          padding: EdgeInsets.all(SizingUtilities.standardPadding),
          child: LayoutBuilder(
            builder: (context, constraint) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
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
                            "Enter a label for your wallet",
                            style: CFTextStyles.textField,
                          ),
                        ),
                        FittedBox(
                          child: Text(
                            "(e.g. My Hot Wallet)",
                            style: CFTextStyles.textField,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20,
                            bottom: 7,
                          ),
                          child: TextField(
                            controller: _nameTextEditingController,
                            style: CFTextStyles.textField,
                            decoration: InputDecoration(
                              hintText: "Enter wallet name",
                              hintStyle: CFTextStyles.textFieldHint,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        if (widget.allowTestNet)
                          Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: _useTestNet,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _useTestNet = newValue;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 14,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  child: Text(
                                    "Test net",
                                    style: GoogleFonts.workSans(
                                      color: CFColors.dusk,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        Spacer(),
                        SizedBox(
                          height: 48,
                          width: MediaQuery.of(context).size.width -
                              (SizingUtilities.standardPadding * 2),
                          child: GradientButton(
                            onTap: () {
                              final walletName =
                                  _nameTextEditingController.text;
                              if (walletName.isEmpty) {
                                OverlayNotification.showError(
                                  context,
                                  "Please name your wallet",
                                  Duration(seconds: 2),
                                );
                              } else {
                                // check if wallet name is already in use
                                final walletsService =
                                    Provider.of<WalletsService>(context,
                                        listen: false);
                                walletsService
                                    .checkForDuplicate(walletName)
                                    .then(
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
                                      await Future.delayed(
                                          Duration(milliseconds: 100));

                                      // continue setting up wallet
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (context) {
                                            return CreatePinView(
                                              type: widget.type,
                                              walletName: walletName,
                                              useTestNet: _useTestNet,
                                            );
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
