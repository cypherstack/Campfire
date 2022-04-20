import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:devicelocale/devicelocale.dart';
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
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
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

  bool _balanceToggleEnabled = true;
  String _locale = "en_US"; // default

  Future<void> _fetchLocale() async {
    _locale = await Devicelocale.currentLocale;
  }

  @override
  void initState() {
    _fetchLocale();
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
                  "AVAILABLE",
                  style: GoogleFonts.workSans(
                    color: Color(0xFFF27889),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 0.25,
                  ),
                ),
                onItem: Text(
                  "FULL",
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
                    Logger.print(
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
                    ? manager.totalBalance
                    : manager.balance,
                builder: (context, AsyncSnapshot<Decimal> snapshot) {
                  String balance = "...";
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    balance = Utilities.localizedStringAsFixed(
                        value: snapshot.data,
                        locale: _locale,
                        decimalPlaces: CampfireConstants.decimalPlaces);
                  }
                  return Text(
                    "$balance ${Provider.of<Manager>(context, listen: false).coinTicker}",
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
              child: Provider<String>.value(
                value: Provider.of<Manager>(context).fiatCurrency,
                builder: (context, child) {
                  String fiatTicker = context.watch<String>();
                  return FutureBuilder(
                    future: _balanceToggleEnabled
                        ? manager.fiatTotalBalance
                        : manager.fiatBalance,
                    builder: (context, AsyncSnapshot<Decimal> snapshot) {
                      String balance = "...";
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data != null) {
                        if (snapshot.data > Decimal.zero) {
                          balance = Utilities.localizedStringAsFixed(
                              value: snapshot.data,
                              locale: _locale,
                              decimalPlaces: CampfireConstants.decimalPlaces);
                        } else {
                          balance = Utilities.localizedStringAsFixed(
                              value: Decimal.zero,
                              locale: _locale,
                              decimalPlaces: CampfireConstants.decimalPlaces);
                        }
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

    return Column(
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
                key: Key("walletViewTransactionSearchButton"),
                onPressed: () {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    barrierDismissible: false,
                    builder: (context) {
                      return TransactionSearchView(
                        coinTicker: manager.coinTicker,
                      );
                    },
                  );
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
          child: TransactionList(
            key: ValueKey("main view transactions list"),
          ),
        ),
      ],
    );
  }
}

class NoTransActionsFound extends StatelessWidget {
  const NoTransActionsFound({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(
          flex: 1,
        ),
        SvgPicture.asset(
          "assets/svg/empty-tx-list.svg",
          width: MediaQuery.of(context).size.width * 0.5,
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
    );
  }
}

class TransactionList extends StatefulWidget {
  const TransactionList({Key key}) : super(key: key);

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  TransactionData txData;

  @override
  Widget build(BuildContext context) {
    return Provider<Future<TransactionData>>.value(
      value: Provider.of<Manager>(context).transactionData,
      builder: (context, child) {
        return FutureBuilder(
          future: context.watch<Future<TransactionData>>(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              txData = snapshot.data;
            }
            if (txData == null || txData.txChunks.length == 0) {
              return NoTransActionsFound();
            } else {
              final list = txData.txChunks
                  .expand((element) => element.transactions)
                  .toList();
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.all(
                        SizingUtilities.listItemSpacing / 2,
                      ),
                      child: TransactionCard(
                        key: ValueKey(list[index]),
                        transaction: list[index],
                      ),
                    );
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}
