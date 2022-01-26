import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/transaction_subviews/transaction_search_view.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/currency_utils.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/draggable_switch_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

class WalletView extends StatefulWidget {
  WalletView({Key key}) : super(key: key);

  @override
  _WalletViewState createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  NodeConnectionStatus _nodeStatus = NodeConnectionStatus.disconnected;

  StreamSubscription _nodeConnectionStatusChangedEventListener;

  List<Transaction> _cachedTransactions = [];

  bool _balanceToggleEnabled = true;

  @override
  void initState() {
    // add listener
    _nodeConnectionStatusChangedEventListener = GlobalEventBus.instance
        .on<NodeConnectionStatusChangedEvent>()
        .listen((event) {
      if (_nodeStatus != event.newStatus) {
        setState(() {
          _nodeStatus = event.newStatus;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _nodeConnectionStatusChangedEventListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<Manager>(context);

    final double _bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        SizingUtilities.bottomToolBarHeight;

    /// list of balances with length of 4 is expected
    // index 0 and 1 for the funds available to spend.
    // index 2 and 3 for all the funds in the wallet (including the undependable ones)
    Widget _buildBalance() {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 160,
              child: DraggableSwitchButton(
                offItem: Text(
                  "FULL",
                  style: GoogleFonts.workSans(
                    color: Color(0xFFF27889),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 0.25,
                  ),
                ),
                onItem: Text(
                  "AVAILABLE",
                  style: GoogleFonts.workSans(
                    color: Color(0xFFF27889),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                  ),
                ),
                onValueChanged: (newValue) {
                  setState(() {
                    _balanceToggleEnabled = newValue;
                    print(
                        "balance switch button changed to: $_balanceToggleEnabled");
                  });
                },
              ),
            ),
            SizedBox(
              height: 14,
            ),
            FittedBox(
              child: FutureBuilder(
                future: _balanceToggleEnabled
                    ? manager.balance
                    : manager.totalBalance,
                builder: (context, AsyncSnapshot<double> snapshot) {
                  String balance = "...";
                  if (snapshot.connectionState == ConnectionState.done) {
                    balance = snapshot.data.toStringAsFixed(8);
                  }
                  return Text(
                    "$balance ${CurrencyUtilities.coinName}",
                    style: GoogleFonts.workSans(
                      color: CFColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 5,
            ),
            FittedBox(
              child: FutureBuilder(
                future: manager.fiatCurrency,
                builder: (context, AsyncSnapshot<String> snapshot) {
                  String fiatTicker = "...";
                  if (snapshot.connectionState == ConnectionState.done) {
                    fiatTicker = snapshot.data;
                  }
                  return FutureBuilder(
                    future: _balanceToggleEnabled
                        ? manager.fiatBalance
                        : manager.fiatTotalBalance,
                    builder: (context, AsyncSnapshot<double> snapshot) {
                      String balance = "...";
                      if (snapshot.connectionState == ConnectionState.done) {
                        balance = snapshot.data.toStringAsFixed(8);
                      }
                      return Text(
                        "$balance $fiatTicker",
                        style: GoogleFonts.workSans(
                          color: CFColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: CFColors.white,
      body: Container(
        height: _bodyHeight -
            10, // needed to fit content on screen. Magic numbers \o/
        color: CFColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: SizingUtilities.standardPadding,
              ),
              child: GradientCard(
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                gradient: CFColors.fireGradientVerticalLight,
                child: Stack(
                  children: [
                    _buildBalance(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Opacity(
                          opacity: 0.5,
                          child: SvgPicture.asset(
                            "assets/svg/groupLogo.svg",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: SizingUtilities.standardPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TRANSACTIONS",
                    style: GoogleFonts.workSans(
                      color: CFColors.twilight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          useSafeArea: false,
                          barrierDismissible: false,
                          builder: (context) {
                            return TransactionSearchView();
                          });
                    },
                    icon: Icon(
                      FeatherIcons.search,
                      color: CFColors.twilight,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (_nodeStatus != NodeConnectionStatus.synced &&
                _nodeStatus != NodeConnectionStatus.disconnected)
              Center(
                child: SpinKitThreeBounce(
                  color: CFColors.spark,
                  size: MediaQuery.of(context).size.width * 0.1,
                ),
              ),
            Expanded(
              child: FutureBuilder(
                future: manager.transactionData,
                builder: (context, AsyncSnapshot<TransactionData> txData) {
                  if (txData.connectionState == ConnectionState.done) {
                    if (_nodeStatus == NodeConnectionStatus.synced) {
                      _cachedTransactions = txData.data.txChunks
                          .expand((element) => element.transactions)
                          .toList();
                    }
                  }
                  if (_cachedTransactions.length == 0) {
                    return _buildNoTransactionsFound(context);
                  } else {
                    return _buildTransactionList(context, _cachedTransactions);
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

_buildNoTransactionsFound(BuildContext context) {
  return Center(
    child: Column(
      children: [
        Spacer(
          flex: 1,
        ),
        SvgPicture.asset(
          "assets/svg/empty-tx-list.svg",
          width: MediaQuery.of(context).size.width * 0.52,
        ),
        SizedBox(
          height: 8,
        ),
        FittedBox(
          child: Text(
            "NO TRANSACTIONS YET",
            style: GoogleFonts.workSans(
              color: CFColors.dew,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.25,
            ),
          ),
        ),
        Spacer(
          flex: 2,
        ),
      ],
    ),
  );
}

// build transaction list after loading data
Widget _buildTransactionList(BuildContext context, List<Transaction> txList) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: 0,
      horizontal: 16,
    ),
    child: ListView.builder(
      itemCount: txList.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.all(
            SizingUtilities.listItemSpacing / 2,
          ),
          child: TransactionCard(
            transaction: txList[index],
            txType: txList[index].txType,
            date: Utilities.extractDateFrom(txList[index].timestamp),
            amount:
                "${Utilities.satoshisToAmount(txList[index].amount)} ${CurrencyUtilities.coinName}",
            fiatValue: txList[index].worthNow is String
                ? txList[index].worthNow
                : txList[index].worthNow.toStringAsFixed(2),
          ),
        );
      },
    ),
  );
}
