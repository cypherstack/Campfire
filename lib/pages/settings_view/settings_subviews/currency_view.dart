import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/coins/manager.dart';
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
    final manager = Provider.of<Manager>(context);
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Currency", onBackPressed: () {
        if (_currencyChanged) manager.refresh();
      }),
      body: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: FutureBuilder(
          future: manager.fiatCurrency,
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
    // create temp list to modify so that the currently selected
    // currency always appears at the top of the list
    final currenciesWithoutSelected = currencyList.toList();
    currenciesWithoutSelected.remove(currentCurrency);
    currenciesWithoutSelected.insert(0, currentCurrency);

    final currenciesCount = currenciesWithoutSelected.length;

    return ListView.separated(
      separatorBuilder: (context, index) => Container(
        height: 1,
        color: CFColors.fog,
      ),
      itemCount: currenciesCount,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () async {
            if (index == 0) {
              // ignore if already selected currency
              return;
            }
            final manager = Provider.of<Manager>(context, listen: false);
            await manager.changeFiatCurrency(currenciesWithoutSelected[index]);
            _currencyChanged = true;
            // Navigator.pop(context);
          },
          child: Container(
            color: index == 0 ? CFColors.fog : CFColors.white,
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
}
