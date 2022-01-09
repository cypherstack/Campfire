import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';

import '../../main_view.dart';

class AddressBookEntryDetailsView extends StatefulWidget {
  const AddressBookEntryDetailsView({
    Key key,
    @required this.name,
    @required this.address,
  }) : super(key: key);

  final String name, address;

  @override
  _AddressBookEntryDetailsViewState createState() => _AddressBookEntryDetailsViewState();
}

class _AddressBookEntryDetailsViewState extends State<AddressBookEntryDetailsView> {
  final _addressTextEditingController = TextEditingController();

  String _name, _address;

  final TextStyle _titleStyle = GoogleFonts.workSans(
    color: CFColors.dusk,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  @override
  initState() {
    _name = widget.name;
    _address = widget.address;
    _addressTextEditingController.text = _address;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        color: CFColors.white,
        height: SizingUtilities.getBodyHeight(context),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: SizingUtilities.standardPadding,
            right: SizingUtilities.standardPadding,
            bottom: SizingUtilities.standardPadding,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Address",
                  style: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              TextField(
                controller: _addressTextEditingController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    FeatherIcons.search,
                    color: CFColors.twilight,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              _buildSendButton(context),
            ],
          ),
        ),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: CFColors.white,
      title: Text(
        _name,
        style: _titleStyle,
      ),
      leadingWidth: 36.0 + 20.0,
      // account for 20 padding

      leading: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 20,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: AppBarIconButton(
            size: 36,
            onPressed: () async {
              FocusScope.of(context).unfocus();
              await Future.delayed(Duration(milliseconds: 50));

              Navigator.pop(context);
            },
            circularBorderRadius: 8,
            icon: SvgPicture.asset(
              "assets/svg/chevronLeft.svg",
              color: CFColors.twilight,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
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
                "assets/svg/more-vertical.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () async {
                FocusScope.of(context).unfocus();
                await Future.delayed(Duration(milliseconds: 50));

                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    return _buildPopupMenu(context);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  _buildPopupMenu(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: SizingUtilities.getStatusBarHeight(context) + 9,
          right: SizingUtilities.standardPadding,
          child: Container(
            decoration: BoxDecoration(
              color: CFColors.white,
              borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
              boxShadow: [CFColors.standardBoxShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO show alert asking for delete confirmation
                    print("delete address pressed");

                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 12,
                      right: 12,
                      bottom: 10,
                    ),
                    child: Text(
                      "Delete address",
                      style: GoogleFonts.workSans(
                        decoration: TextDecoration.none,
                        color: CFColors.midnight,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildSendButton(BuildContext context) {
    return SizedBox(
      height: SizingUtilities.standardButtonHeight,
      width: MediaQuery.of(context).size.width - (SizingUtilities.standardPadding * 2),
      child: GradientButton(
        child: FittedBox(
          child: Text(
            "SEND",
            style: CFTextStyles.button,
          ),
        ),
        onTap: () {
          print("SEND button pressed");
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (context) {
              return MainView(
                pageIndex: 0, // 0 for send page index
                args: {
                  "addressBookEntry": {
                    "name": _name,
                    "address": _address,
                  },
                },
                disableRefreshOnInit: true,
              );
            }),
            ModalRoute.withName("/mainview"),
          );
        },
      ),
    );
  }
}
