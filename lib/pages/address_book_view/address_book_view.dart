import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/address_book_card.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:provider/provider.dart';

class AddressBookView extends StatefulWidget {
  const AddressBookView({Key key}) : super(key: key);

  @override
  _AddressBookViewState createState() => _AddressBookViewState();
}

class _AddressBookViewState extends State<AddressBookView> {
  var appBarTitle = "Address Book";

  TextEditingController searchTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);

    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: AppBar(
        backgroundColor: CFColors.white,
        title: Text(
          appBarTitle,
          style: TextStyle(
            color: CFColors.dusk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        // trailing appbar button
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
                  "assets/svg/plus.svg",
                  color: CFColors.twilight,
                ),
                // icon: Icon(
                //   FeatherIcons.plus,
                //   size: 24,
                //   color: ColorStyles.twilight,
                // ),
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                onPressed: () {
                  Navigator.pushNamed(context, "/addaddressbookentry");
                },
              ),
            ),
          ),
        ],
        // leading appbar button
        leadingWidth: 36.0 + 20.0, // account for 20 padding
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
                onPressed: () {
                  Navigator.pop(context);
                },
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                icon: SvgPicture.asset(
                  "assets/svg/chevronLeft.svg",
                  color: CFColors.twilight,
                )
                // icon: Icon(
                //   FeatherIcons.chevronLeft,
                //   // size: 24,
                //   color: ColorStyles.twilight,
                // ),
                ),
          ),
        ),
      ),
      body: Container(
        height: SizingUtilities.getBodyHeight(context),
        child: Column(
          children: [
            // search field
            // TODO: implement search
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
                bottom: 11,
              ),
              child: TextField(
                controller: searchTextEditingController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    FeatherIcons.search,
                    color: CFColors.twilight,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: bitcoinService.addressBookEntries,
                builder: (context, entries) {
                  if (entries.connectionState == ConnectionState.done) {
                    return _buildAddressBookEntryList(context, entries);
                  } else {
                    return Center(
                      child: SpinKitThreeBounce(
                        color: CFColors.spark,
                        size: MediaQuery.of(context).size.width * 0.25,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAddressBookEntryList(
    BuildContext context, AsyncSnapshot<Map<String, String>> entries) {
  // No transactions in wallet
  if (entries.data == null || entries.data.length == 0) {
    return Center(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
          ),
          SvgPicture.asset(
            "assets/svg/empty-address-list.svg",
            width: MediaQuery.of(context).size.width * 0.52,
          ),
          SizedBox(
            height: 8,
          ),
          FittedBox(
            child: Text(
              "NO ADDRESSES YET",
              style: GoogleFonts.workSans(
                color: CFColors.dew,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.25,
              ),
            ),
          )
        ],
      ),
    );
  } else {
    final addresses = entries.data.keys.toList().reversed.toList();
    return Container(
      child: ListView.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: SizingUtilities.listItemSpacing / 2,
              horizontal: 20,
            ),
            child: AddressBookCard(
              name: entries.data[addresses[index]],
              address: addresses[index],
            ),
          );
        },
      ),
    );
  }
}
