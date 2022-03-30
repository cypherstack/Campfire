import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/address_book_view/subviews/address_book_entry_details_view.dart';
import 'package:paymint/pages/main_view.dart';
import 'package:paymint/utilities/logger.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.circular(
          SizingUtilities.circularBorderRadius,
        ),
        boxShadow: [
          CFColors.standardBoxShadow,
        ],
      ),
      child: Column(
        children: [
          MaterialButton(
            padding: EdgeInsets.zero,
            shape: _isExpanded
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        SizingUtilities.circularBorderRadius,
                      ),
                    ),
                  )
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      SizingUtilities.circularBorderRadius,
                    ),
                  ),
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
                  SubButton(
                    svgAsset: "assets/svg/upload-2.svg",
                    label: "SEND FIRO",
                    onTap: () {
                      Logger.print("send firo");
                      Navigator.pushAndRemoveUntil(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => MainView(
                            pageIndex: 0, // 0 for send page index
                            args: {
                              "addressBookEntry": {
                                "name": widget.name,
                                "address": widget.address,
                              },
                            },
                            disableRefreshOnInit: true,
                          ),
                          settings: RouteSettings(name: "/mainview"),
                        ),
                        ModalRoute.withName("/"),
                      );
                    },
                  ),

                  // copy
                  SubButton(
                    svgAsset: "assets/svg/copy-2.svg",
                    label: "COPY",
                    onTap: () {
                      Clipboard.setData(
                        new ClipboardData(
                          text: widget.address,
                        ),
                      );
                      OverlayNotification.showInfo(
                        context,
                        "Address copied to clipboard",
                        Duration(seconds: 2),
                      );
                    },
                  ),

                  // details
                  SubButton(
                    svgAsset: "assets/svg/eye.svg",
                    label: "DETAILS",
                    onTap: () {
                      Logger.print("details");
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => AddressBookEntryDetailsView(
                              name: widget.name, address: widget.address),
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

class SubButton extends StatelessWidget {
  const SubButton({
    Key key,
    this.svgAsset,
    this.label,
    this.onTap,
  }) : super(key: key);

  final String svgAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            style: GoogleFonts.workSans(
              color: CFColors.dusk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          )
        ],
      ),
    );
  }
}
