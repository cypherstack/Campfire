import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';

import '../helpers/builders.dart';

class CurrencyView extends StatefulWidget {
  const CurrencyView({Key key}) : super(key: key);

  @override
  _CurrencyViewState createState() => _CurrencyViewState();
}

class _CurrencyViewState extends State<CurrencyView> {
  final currencyList = [
    "AUD",
    "CAD",
    "CHF",
    "CNY",
    "EUR",
    "GBP",
    "HKD",
    "INR",
    "JPY",
    "KRW",
    "PHP",
    "SGD",
    "TRY",
    "USD",
    "XAU",
  ];

  bool _currencyChanged = false;

  @override
  Widget build(BuildContext context) {
    final bitcoinService = Provider.of<BitcoinService>(context);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Currency", onBackPressed: () {
        if (_currencyChanged) bitcoinService.refreshWalletData();
      }),
      body: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: FutureBuilder(
          future: bitcoinService.currency,
          builder: (BuildContext context, AsyncSnapshot<String> currency) {
            if (currency.connectionState == ConnectionState.done) {
              final selectedCurrency = currency.data;
              return _buildCurrencyList(context, selectedCurrency);
            } else {
              return Center(
                child: SpinKitThreeBounce(
                  color: CFColors.spark,
                  size: MediaQuery.of(context).size.width * 0.1,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  _buildCurrencyList(BuildContext context, String currentCurrency) {
    final currenciesWithoutSelected = currencyList.toList();
    currenciesWithoutSelected.remove(currentCurrency);
    currenciesWithoutSelected.insert(0, currentCurrency);

    return ListView.separated(
      separatorBuilder: (context, index) => Divider(
        color: CFColors.fog,
        height: 1,
      ),
      itemCount: currenciesWithoutSelected.length,
      itemBuilder: (BuildContext context, int index) {
        return MaterialButton(
          color: index == 0 ? CFColors.fog : CFColors.white,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () async {
            if (index == 0) {
              // ignore if already selected currency
              return;
            }

            // showModal(
            //   context: context,
            //   configuration: FadeScaleTransitionConfiguration(barrierDismissible: false),
            //   builder: (BuildContext context) {
            //     return _currencySwitchDialog(currenciesWithoutSelected[index]);
            //   },
            // );
            final BitcoinService btcService =
                Provider.of<BitcoinService>(context, listen: false);
            await btcService.changeCurrency(currenciesWithoutSelected[index]);
            _currencyChanged = true;
            // Navigator.pop(context);
          },
          child: Container(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              child: Text(
                index == 0 ? currentCurrency : currenciesWithoutSelected[index],
                style: GoogleFonts.workSans(
                  color: index == 0 ? CFColors.spark : CFColors.starryNight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.25,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  //
  // _currencySwitchDialog(String newCurrency) {
  //   return AlertDialog(
  //     backgroundColor: Colors.black,
  //     title: Row(
  //       children: <Widget>[
  //         CircularProgressIndicator(),
  //         SizedBox(width: 16),
  //         Text(
  //           'Switching currency...',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //       ],
  //     ),
  //     content: Text(
  //       "Please wait while we refresh wallet data in $newCurrency",
  //       style: TextStyle(color: Colors.white),
  //     ),
  //   );
  // }
}
