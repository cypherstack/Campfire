import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/address_book_view/address_book_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/currency_view.dart';
import 'package:paymint/pages/settings_view/settings_subviews/network_settings_view.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

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
                  Navigator.push(context, CupertinoPageRoute(builder: (context) {
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
                  Navigator.push(context, CupertinoPageRoute(builder: (context) {
                    return NetworkSettingsView();
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
                "assets/svg/key.svg",
                "Wallet Backup",
                () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) {
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
                "assets/svg/settings.svg",
                "Wallet Settings",
                () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) {
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
                "assets/svg/dollar-sign.svg",
                "Currency",
                () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) {
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
