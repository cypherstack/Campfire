import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/modal_popup_dialog.dart';
import 'package:paymint/pages/address_book_view/address_book_view.dart';
import 'package:paymint/pages/lockscreen2.dart';
import 'package:paymint/pages/settings_view/settings_subviews/currency_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/wallet_settings_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/wallets_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:provider/provider.dart';

import '../wallet_selection_view.dart';
import 'helpers/builders.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key key}) : super(key: key);

//   @override
//   _SettingsViewState createState() => _SettingsViewState();
// }
//
// class _SettingsViewState extends State<SettingsView> {
  // @override
  // void initState() {
  //   // show system status bar
  //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //       overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  //
  //   SystemChrome.setSystemUIOverlayStyle(
  //     SystemUiOverlayStyle(
  //       statusBarColor: Colors.transparent,
  //       statusBarIconBrightness: Brightness.dark,
  //       // statusBarBrightness: Brightness.dark,
  //     ),
  //   );
  //   super.initState();
  // }
  //
  // final _itemTextStyle = GoogleFonts.workSans(
  //   color: CFColors.starryNight,
  //   fontWeight: FontWeight.w600,
  //   fontSize: 16,
  //   letterSpacing: 0.25,
  // );

  _buildItem(String iconAsset, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        height: SizingUtilities.standardButtonHeight,
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              color: CFColors.twilight,
              height: 24,
              width: 24,
            ),
            SizedBox(
              width: SizingUtilities.standardPadding,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  child: Text(
                    text,
                    style: GoogleFonts.workSans(
                      color: CFColors.starryNight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Settings",
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
                final BitcoinService bitcoinService =
                    Provider.of<BitcoinService>(context, listen: false);
                final walletsService =
                    Provider.of<WalletsService>(context, listen: false);
                final walletName = await walletsService.currentWalletName;

                showDialog(
                  useSafeArea: false,
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
                                    height:
                                        SizingUtilities.standardButtonHeight,
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
                                    height:
                                        SizingUtilities.standardButtonHeight,
                                    child: GradientButton(
                                      child: FittedBox(
                                        child: Text(
                                          "LOG OUT",
                                          style: CFTextStyles.button,
                                        ),
                                      ),
                                      onTap: () async {
                                        print("log out pressed");
                                        await bitcoinService.clearWalletData();
                                        await walletsService.refreshWallets();

                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          CupertinoPageRoute(
                                            maintainState: false,
                                            builder: (_) =>
                                                WalletSelectionView(),
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
        padding: const EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 22,
              ),
              // address book item
              _buildItem(
                "assets/svg/book-open.svg",
                "Address Book",
                () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                    return AddressBookView();
                  }));
                },
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/radio.svg",
                "Network",
                () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                    return NetworkSettingsView();
                    // return NodeDetailsView(isEdit: false);
                  }));
                },
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/lock.svg",
                "Wallet Backup",
                () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                    return Lockscreen2View(
                      routeOnSuccess: '/settings/walletbackup',
                      biometricsAuthenticationTitle: "Show backup key",
                      biometricsCancelButtonString: "CANCEL",
                      biometricsLocalizedReason:
                          "Unlock using fingerprint to show backup key",
                    );
                  }));
                },
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/settings.svg",
                "Wallet Settings",
                () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                    return WalletSettingsView();
                  }));
                },
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: CFColors.fog,
              ),
              // address book item
              _buildItem(
                "assets/svg/usd-circle.svg",
                "Currency",
                () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (context) {
                    return CurrencyView();
                  }));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
