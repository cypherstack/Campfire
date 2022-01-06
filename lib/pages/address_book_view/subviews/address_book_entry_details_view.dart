import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';

class AddressBookEntryDetailsView extends StatelessWidget {
  AddressBookEntryDetailsView({
    Key key,
    @required this.name,
    @required this.address,
  }) : super(key: key);

  final String name;
  final String address;

  final addressTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            name,
            style: GoogleFonts.workSans(
              color: CFColors.dusk,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        body: Container(
          color: CFColors.white,
          height: SizingUtilities.getBodyHeight(context),
          child: Column(
            children: [
              Text(
                "Address",
                style: GoogleFonts.workSans(
                  color: CFColors.twilight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 20,
                  right: 20,
                  bottom: 11,
                ),
                child: TextField(
                  controller: addressTextEditingController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      FeatherIcons.search,
                      color: CFColors.twilight,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
