import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/pages/transaction_subviews/transaction_details_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/globals.dart';
import 'package:paymint/services/notes_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';

class TransactionCard extends StatefulWidget {
  const TransactionCard(
      {Key key,
      this.txType,
      this.date,
      this.amount,
      this.fiatValue,
      @required this.transaction})
      : super(key: key);

  final String txType;
  final String date;
  final String amount;
  final String fiatValue;

  final Transaction transaction;

  @override
  _TransactionCardState createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  String _txType;
  String _date;
  String _amount;
  String _fiatValue;

  Transaction _transaction;

  @override
  void initState() {
    _txType = widget.txType;
    _date = widget.date;
    _amount = widget.amount;
    _fiatValue = widget.fiatValue;
    _transaction = widget.transaction;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String type = _txType;
    Icon icon;

    if (_txType == "Received") {
      color = CFColors.success;
      icon = Icon(
        FeatherIcons.arrowDown,
        color: color,
        size: 20,
      );
    } else if (_txType == "Sent") {
      color = CFColors.spark;
      type = "Sent";
      icon = Icon(
        FeatherIcons.arrowUp,
        color: color,
        size: 20,
      );
      //TODO: Not sure if needed.
      // Are there any other txTypes strings?
      // Maybe use enum for this
    } else {
      // unknown edge cases
      color = CFColors.warning;
      type = "Unknown";
      icon = Icon(
        Icons.warning_rounded,
        color: color,
        size: 20,
      );
    }

    String whatIsIt() {
      if (type == "Received") {
        if (_transaction.confirmedStatus) {
          if (_transaction.height == -1) {
            return "Minting";
          } else {
            return "Received";
          }
        } else {
          return "Receiving";
        }
      } else {
        if (_transaction.confirmedStatus) {
          return "Sent";
        } else {
          return "Sending";
        }
      }
    }

    final notesService = Provider.of<NotesService>(context, listen: false);

    return Material(
      color: CFColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(SizingUtilities.circularBorderRadius),
      ),
      child: GestureDetector(
        onTap: () async {
          final note = await notesService.getNoteFor(txid: _transaction.txid);
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) {
                return TransactionDetailsView(
                  transaction: _transaction,
                  note: note,
                );
              },
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: CFColors.white,
            borderRadius:
                BorderRadius.circular(SizingUtilities.circularBorderRadius),
            boxShadow: [
              CFColors.standardBoxShadow,
            ],
          ),
          child: Row(
            children: [
              // gray circle with icon
              Container(
                margin: EdgeInsets.all(14),
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: CFColors.fog,
                ),
                child: icon,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 16, bottom: 16, right: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                whatIsIt(),
                                style: GoogleFonts.workSans(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _amount,
                                style: GoogleFonts.workSans(
                                  color: CFColors.starryNight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _date,
                                style: GoogleFonts.workSans(
                                  color: CFColors.twilight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Flexible(
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Provider<Future<Decimal>>.value(
                                  value:
                                      Provider.of<Manager>(context).fiatPrice,
                                  builder: (context, child) {
                                    final manager = Provider.of<Manager>(
                                        context,
                                        listen: false);
                                    return FutureBuilder(
                                      future: context.watch<Future<Decimal>>(),
                                      builder: (context,
                                          AsyncSnapshot<Decimal> snapshot) {
                                        String symbol = "";
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          final value = snapshot.data *
                                              Utilities.satoshisToAmount(
                                                  _transaction.amount);
                                          _fiatValue = value < Decimal.zero
                                              ? "..."
                                              : value.toStringAsFixed(8);

                                          symbol =
                                              currencyMap[manager.fiatCurrency];
                                        }
                                        return Text(
                                          symbol + _fiatValue,
                                          style: GoogleFonts.workSans(
                                            color: CFColors.twilight,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )),
                          ),
                        ],
                      ),
                    ],
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
