import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/address_book_view/subviews/address_book_entry_details_view.dart';
import 'package:paymint/pages/main_view.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

import '../utilities/cfcolors.dart';

class AddressBookCard extends StatefulWidget {
  const AddressBookCard({Key key, this.name, this.address}) : super(key: key);

  final String name;
  final String address;

  @override
  _AddressBookCardState createState() => _AddressBookCardState();
}

class _AddressBookCardState extends State<AddressBookCard> {
  bool _isExpanded = false;

  TextStyle _getSubButtonTextStyle() {
    return GoogleFonts.workSans(
      color: CFColors.dusk,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
    );
  }

  ShapeBorder _getMaterialShape() {
    if (_isExpanded) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SizingUtilities.circularBorderRadius),
        ),
      );
    } else {
      return RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
      );
    }
  }

  Widget _buildSubButton(String svgAsset, String label, VoidCallback onTap) {
    return MaterialButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.all(8),
      onPressed: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            svgAsset,
            color: CFColors.dusk,
            width: 16,
            height: 16,
          ),
          SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: _getSubButtonTextStyle(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.white,
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
        boxShadow: [
          CFColors.standardBoxShadow,
        ],
      ),
      child: Column(
        children: [
          MaterialButton(
            padding: EdgeInsets.zero,
            shape: _getMaterialShape(),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            // container used to register tap on whole card
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        gradient: CFColors.fireGradientVerticalLight,
                        borderRadius: BorderRadius.circular(
                            18), // half with for perfect circle
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          "assets/svg/address-contact.svg",
                          color: CFColors.white,
                          // size: 20,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 14,
                    ),
                    Text(
                      widget.name,
                      style: GoogleFonts.workSans(
                        color: CFColors.starryNight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.25,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // separator
          if (_isExpanded)
            Container(
              height: 1,
              color: CFColors.fog,
            ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // send
                  _buildSubButton(
                    "assets/svg/upload-2.svg",
                    "SEND FIRO",
                    () {
                      print("send firo");
                      Navigator.pushAndRemoveUntil(
                        context,
                        CupertinoPageRoute(builder: (context) {
                          return MainView(
                            pageIndex: 0, // 0 for send page index
                            args: {
                              "addressBookEntry": {
                                "name": widget.name,
                                "address": widget.address,
                              },
                            },
                            disableRefreshOnInit: true,
                          );
                        }),
                        ModalRoute.withName("/mainview"),
                      );
                    },
                  ),

                  // copy
                  _buildSubButton(
                    "assets/svg/copy-2.svg",
                    "COPY",
                    () {
                      Clipboard.setData(
                          new ClipboardData(text: widget.address));
                      OverlayNotification.showInfo(
                        context,
                        "Address copied to clipboard",
                        Duration(seconds: 2),
                      );
                    },
                  ),

                  // details
                  _buildSubButton(
                    "assets/svg/eye.svg",
                    "DETAILS",
                    () {
                      print("details");
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) {
                            return AddressBookEntryDetailsView(
                                name: widget.name, address: widget.address);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
