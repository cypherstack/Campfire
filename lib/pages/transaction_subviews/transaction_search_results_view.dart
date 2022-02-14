import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/transactions_model.dart';
import 'package:paymint/pages/settings_view/helpers/builders.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/currency_utils.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

class TransactionSearchResultsView extends StatelessWidget {
  const TransactionSearchResultsView({
    Key key,
    this.start,
    this.end,
    this.sent,
    this.received,
    this.keyword,
    this.amount,
    this.notes,
    this.contacts,
  }) : super(key: key);

  final DateTime start;
  final DateTime end;
  final bool sent;
  final bool received;
  final String keyword;
  final double amount;

  final Map<String, String> notes;
  final Map<String, String> contacts;

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      // check if either both are checked or unchecked
      if (received != null && sent != null && sent == received) {
        return _isAmountMatch(tx) &&
            _isAfter(tx) &&
            _isBefore(tx) &&
            _isKeywordMatch(tx);

        // otherwise check for sent
      } else if (sent != null && sent) {
        return _isAmountMatch(tx) &&
            _isSent(tx) &&
            _isAfter(tx) &&
            _isBefore(tx) &&
            _isKeywordMatch(tx);

        // otherwise check for received
      } else if (received != null && received) {
        return _isAmountMatch(tx) &&
            _isReceived(tx) &&
            _isAfter(tx) &&
            _isBefore(tx) &&
            _isKeywordMatch(tx);
      }
      return false;
    }).toList();
  }

  // transaction search criteria matches
  // null returns true as criteria not set
  bool _isAmountMatch(Transaction tx) =>
      amount == null || tx.amount == (amount * 100000000.0).toInt();

  bool _isReceived(Transaction tx) =>
      received == null || tx.txType == "Received";

  bool _isSent(Transaction tx) => sent == null || tx.txType == "Sent";

  bool _isAfter(Transaction tx) =>
      start == null || tx.timestamp >= start.millisecondsSinceEpoch / 1000;

  bool _isBefore(Transaction tx) =>
      end == null || tx.timestamp <= end.millisecondsSinceEpoch / 1000;

  bool _isKeywordMatch(Transaction tx) {
    if (keyword == null) {
      return true;
    }

    bool contains = false;

    if (contacts != null) {
      // check if addressbook name contains
      contains |= contacts[tx.address] != null &&
          contacts[tx.address].contains(keyword);
    }
    // check if address contains
    contains |= tx.address.contains(keyword);

    if (notes != null) {
      // check if note contains
      contains |= notes[tx.txid] != null && notes[tx.txid].contains(keyword);
    }
    // check if txid contains
    contains |= tx.txid.contains(keyword);

    return contains;
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Search results"),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding -
              (SizingUtilities.listItemSpacing / 2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 6,
            ),
            _buildSearchCriteriaRow(),
            SizedBox(
              height: 16,
            ),
            Expanded(
              child: FutureBuilder(
                future: manager.transactionData,
                builder: (context, AsyncSnapshot<TransactionData> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data != null && !snapshot.hasError) {
                      return _buildTransactionList(context, snapshot.data);
                    }
                  }
                  return Center(
                    child: SpinKitThreeBounce(
                      color: CFColors.spark,
                      size: MediaQuery.of(context).size.width * 0.1,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: SizingUtilities.standardPadding,
            )
          ],
        ),
      ),
    );
  }

  _buildSearchCriteriaBox(String label) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Text(
          label,
          style: GoogleFonts.workSans(
            color: CFColors.twilight,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  _buildSearchCriteriaRow() {
    // format date display
    String dateString = start == null
        ? Utilities.formatDate(DateTime(2007))
        : Utilities.formatDate(start);
    dateString += "-";
    dateString += end == null
        ? Utilities.formatDate(DateTime.now())
        : Utilities.formatDate(end);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SizingUtilities.listItemSpacing / 2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (received != null && received)
              _buildSearchCriteriaBox("Received"),
            if (received != null && received)
              SizedBox(
                width: 8,
              ),
            if (sent != null && sent) _buildSearchCriteriaBox("Sent"),
            if (sent != null && sent)
              SizedBox(
                width: 8,
              ),
            if (start != null || end != null)
              _buildSearchCriteriaBox(dateString),
            if (start != null || end != null)
              SizedBox(
                width: 8,
              ),
            if (amount != null)
              _buildSearchCriteriaBox("$amount ${CurrencyUtilities.coinName}"),
            if (amount != null)
              SizedBox(
                width: 8,
              ),
            if (keyword != null && keyword.isNotEmpty)
              _buildSearchCriteriaBox(keyword),
          ],
        ),
      ),
    );
  }

  _buildTransactionList(BuildContext context, TransactionData txData) {
    // TODO optimize tx search
    final list =
        txData.txChunks.expand((element) => element.transactions).toList();

    // hide/remove self lelantus mints. They are needed in backend for calculating balances correctly
    list.removeWhere(
      (tx) => tx.fees == 0 && tx.amount == 0 && tx.txType == "Received",
    );

    final results = _filterTransactions(list);
    if (results.length == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/svg/empty-tx-list.svg",
              width: MediaQuery.of(context).size.width * 0.52,
            ),
            SizedBox(
              height: 8,
            ),
            FittedBox(
              child: Text(
                "NO MATCHING TRANSACTIONS FOUND",
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
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(
              SizingUtilities.listItemSpacing / 2,
            ),
            child: TransactionCard(
              transaction: results[index],
              txType: results[index].txType,
              date: Utilities.extractDateFrom(results[index].timestamp),
              amount:
                  "${Utilities.satoshiAmountToPrettyString(results[index].amount)} ${CurrencyUtilities.coinName}",
              fiatValue: results[index].worthNow,
            ),
          );
        },
      );
    }
  }
}
