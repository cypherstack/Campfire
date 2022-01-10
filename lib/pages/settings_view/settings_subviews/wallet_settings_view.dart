import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/pages/wallet_selection_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

class WalletSettingsView extends StatefulWidget {
  const WalletSettingsView({Key key}) : super(key: key);

  @override
  _WalletSettingsViewState createState() => _WalletSettingsViewState();
}

class _WalletSettingsViewState extends State<WalletSettingsView> {
  final _itemTextStyle = GoogleFonts.workSans(
    color: CFColors.starryNight,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.25,
  );

  // TODO load in data from db
  bool _biometricsSwitchIsActive = false;

  @override
  Widget build(BuildContext context) {
    final _itemWidth =
        MediaQuery.of(context).size.width - (SizingUtilities.standardPadding * 2);

    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Wallet Settings",
        rightButton: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/log-out.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () async {
                final walletName =
                    await Provider.of<BitcoinService>(context, listen: false)
                        .currentWalletName;

                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    return ModalPopupDialog(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Text(
                              "Do you want to log out from $walletName Wallet?",
                              style: GoogleFonts.workSans(
                                color: CFColors.dusk,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                              left: SizingUtilities.standardPadding,
                              right: SizingUtilities.standardPadding,
                              bottom: SizingUtilities.standardPadding,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: SizingUtilities.standardButtonHeight,
                                    child: SimpleButton(
                                      child: FittedBox(
                                        child: Text(
                                          "CANCEL",
                                          style: CFTextStyles.button.copyWith(
                                            color: CFColors.dusk,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: SizingUtilities.standardButtonHeight,
                                    child: GradientButton(
                                      child: FittedBox(
                                        child: Text(
                                          "LOG OUT",
                                          style: CFTextStyles.button,
                                        ),
                                      ),
                                      onTap: () {
                                        print("log out pressed");
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) => WalletSelectionView(),
                                          ),
                                          (_) => false,
                                        );
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildOptionsList(context, _itemWidth),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList(BuildContext context, double itemWidth) {
    return [
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () {
            //TODO implement change pin
            print("change pin pressed");
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Change PIN",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
      _buildDivider(itemWidth),
      GestureDetector(
        onTap: () {
          //TODO implement Enable biometric authentication
          print("Enable biometric authentication: $_biometricsSwitchIsActive");
          setState(() {
            _biometricsSwitchIsActive = !_biometricsSwitchIsActive;
          });
        },
        child: Row(
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 16,
                  right: 10,
                ),
                child: Text(
                  "Enable biometric authentication",
                  style: _itemTextStyle,
                ),
              ),
            ),
            Spacer(),
            _buildSwitch(context, 18, 36),
          ],
        ),
      ),
      _buildDivider(itemWidth),
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () {
            //TODO implement rename wallet
            print("rename wallet pressed");
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Rename wallet",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
      _buildDivider(itemWidth),
      Container(
        // width: itemWidth,
        child: GestureDetector(
          onTap: () {
            //TODO implement delete wallet
            print("delete wallet pressed");
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16,
              right: 10,
            ),
            child: Text(
              "Delete wallet",
              style: _itemTextStyle,
            ),
          ),
        ),
      ),
    ];
  }

  _buildSwitch(BuildContext context, double height, double width) {
    return Container(
      height: height,
      width: width,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _biometricsSwitchIsActive ? CFColors.spark : CFColors.fog,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: _biometricsSwitchIsActive ? CFColors.spark : CFColors.dew,
                width: 2,
              ),
            ),
          ),
          Container(
            height: height,
            width: width,
            child: Row(
              mainAxisAlignment: _biometricsSwitchIsActive
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                // if (_enabled) Spacer(),
                Container(
                  height: height,
                  width: height,
                  decoration: BoxDecoration(
                    color: CFColors.white,
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(
                      color: _biometricsSwitchIsActive ? CFColors.spark : CFColors.dew,
                      width: 2,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildDivider(double width) {
    return Container(
      height: 1,
      width: width,
      color: CFColors.fog,
    );
  }
}
