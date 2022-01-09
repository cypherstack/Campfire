import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/address_book_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';

class TransactionDetailsView extends StatelessWidget {
  const TransactionDetailsView({Key key, @required this.transaction}) : super(key: key);

  final Transaction transaction;

  Color _txTypeColor() {
    if (transaction.txType == "Received") {
      return CFColors.success;
    } else if (transaction.txType == "Sent") {
      return CFColors.spark;
    } else {
      // Are there any other txTypes strings?
      // Maybe use enum for this
      // unknown edge cases
      return CFColors.warning;
    }
  }

  String _getTitle() {
    if (transaction.txType == "Received") {
      if (transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving (~10 min)";
      }
    } else if (transaction.txType == "Sent") {
      if (transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending (~10 min)";
      }
    } else {
      // Are there any other txTypes strings?
      // Maybe use enum for this
      // unknown edge cases
      return "Unknown";
    }
  }

  get _labelStyle => GoogleFonts.workSans(
        color: CFColors.twilight,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );
  get _contentStyle => GoogleFonts.workSans(
        color: CFColors.midnight,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      );

  // TODO need to store sent to address for transactions on server for this
  _buildSentToItem(BuildContext context) {
    final addressService = Provider.of<AddressBookService>(context, listen: false);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              "Sent to:",
              style: _labelStyle,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        FutureBuilder(
          future: addressService.addressBookEntries,
          builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // TODO: need address to match up and find contact name
              final address = "";

              return Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  child: Text(
                    snapshot.data[address],
                    style: _contentStyle,
                  ),
                ),
              );
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                child: Text(
                  "snapshot.data[address]",
                  style: _contentStyle,
                ),
              ),
            );
          },
        )
      ],
    );
  }

  _buildSeparator() {
    return SizedBox(
      height: 25,
      child: Center(
        child: Container(
          color: CFColors.fog,
          height: 1,
          width: double.infinity,
        ),
      ),
    );
  }

  _buildItem(String label, String content) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            child: Text(
              label,
              style: _labelStyle,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            content,
            style: _contentStyle,
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(
        context,
        "Transaction Details",
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding,
        ),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 10,
            ),
            Container(
              height: SizingUtilities.standardButtonHeight,
              decoration: BoxDecoration(
                color: CFColors.fog,
                borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    _getTitle(),
                    style: GoogleFonts.workSans(
                      color: _txTypeColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // TODO need to store Note for transaction on server for this
                    _buildItem("Note:", "not implemented yet"),
                    _buildSeparator(),
                    // if (transaction.txType == "Sent") _buildSentToItem(context),
                    // _buildSeparator(),
                    _buildItem("Amount:",
                        Utilities.satoshiAmountToPrettyString(transaction.amount)),
                    _buildSeparator(),
                    _buildItem(
                        "Fee:", Utilities.satoshiAmountToPrettyString(transaction.fees)),
                    _buildSeparator(),
                    _buildItem("Date:", Utilities.extractDateFrom(transaction.timestamp)),
                    _buildSeparator(),
                    _buildItem("Transaction ID:", transaction.txid),
                    _buildSeparator(),
                    // TODO transaction block height
                    _buildItem("Block Height:", "not implemented yet"),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            ),
          ],
        ),
      ),
    );
  }
}
