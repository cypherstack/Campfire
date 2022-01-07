import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

import '../helpers/builders.dart';

class NetworkSettingsView extends StatefulWidget {
  const NetworkSettingsView({Key key}) : super(key: key);

  @override
  _NetworkSettingsViewState createState() => _NetworkSettingsViewState();
}

class _NetworkSettingsViewState extends State<NetworkSettingsView> {
  final _labelTextStyle = GoogleFonts.workSans(
    color: CFColors.twilight,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );

  final _itemTextStyle = GoogleFonts.workSans(
    color: CFColors.starryNight,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 0.25,
  );

  //TODO add listener to this class to setState for updating this label
  String _blockchainStatusLabel = "Synchronized";

  // _addNode(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Settings",
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: SizingUtilities.standardPadding,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: Text(
                  "Blockchain Status",
                  style: _labelTextStyle,
                ),
              ),
            ),
            Container(
              height: 52,
              child: Row(
                children: [
                  SizedBox(
                    width: 8,
                  ),
                  SvgPicture.asset(
                    "assets/svg/check-circle2.svg",
                    color: CFColors.success,
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(
                    width: SizingUtilities.standardPadding,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: Text(
                        _blockchainStatusLabel,
                        style: _itemTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: Text(
                  "My Nodes",
                  style: _labelTextStyle,
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
