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
                // children: _buildNodeList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildNodeList(BuildContext context) {
  //   List<Widget> list = [];
  //   // TODO fetch nodes and build list of _buildNodeListItem
  //
  //   list.add(_buildNodeListItem(context, "test name", true));
  //   list.add(_buildNodeListItem(context, "test name2", false));
  //   list.add(_buildNodeListItem(context, "test name3", true));
  //
  //   return list;
  // }
  //
  // _buildNodeListItem(BuildContext context, String nodeName, bool isConnected) {
  //   var color = CFColors.white;
  //   return GestureDetector(
//        onTapDown
  //     onTap: () {
  //       setState(() {
  //         color = CFColors.fog;
  //       });
  //     },
  //     child: Container(
  //       color: color,
  //       child: Padding(
  //         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
  //         child: Row(
  //           children: [
  //             SvgPicture.asset(
  //               "assets/svg/globe.svg",
  //               height: 24,
  //               width: 24,
  //               color: CFColors.twilight,
  //             ),
  //             SizedBox(
  //               width: 18,
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   nodeName,
  //                   style: GoogleFonts.workSans(
  //                     color: CFColors.starryNight,
  //                     fontWeight: FontWeight.w600,
  //                     fontSize: 14,
  //                     letterSpacing: 0.25,
  //                   ),
  //                 ),
  //                 if (isConnected)
  //                   Text(
  //                     "Connected",
  //                     style: GoogleFonts.workSans(
  //                       color: CFColors.twilight,
  //                       fontWeight: FontWeight.w500,
  //                       fontSize: 12,
  //                     ),
  //                   )
  //               ],
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
