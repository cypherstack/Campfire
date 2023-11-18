import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/services/coins/manager.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/logger.dart';
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
    "RUB",
    "IDR",
    "VND",
    "MYR",
    "THB",
    "XAU",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: buildSettingsAppBar(context, "Currency"),
      body: Padding(
        padding: EdgeInsets.only(
          top: 12,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: Provider<String>.value(
          value: Provider.of<Manager>(context).fiatCurrency,
          builder: (context, child) {
            return CurrencyList(
              currencies: currencyList,
              currentCurrency: context.watch<String>(),
            );
          },
        ),
      ),
    );
  }
}

class CurrencyList extends StatefulWidget {
  const CurrencyList({Key key, this.currencies, this.currentCurrency})
      : super(key: key);

  final List<String> currencies;
  final String currentCurrency;

  @override
  _CurrencyListState createState() => _CurrencyListState();
}

class _CurrencyListState extends State<CurrencyList> {
  @override
  Widget build(BuildContext context) {
    String current = widget.currentCurrency;
    // create temp list to modify so that the currently selected
    // currency always appears at the top of the list
    final currenciesWithoutSelected = widget.currencies;
    if (current.isNotEmpty) {
      currenciesWithoutSelected.remove(current);
      currenciesWithoutSelected.insert(0, current);
    }

    return ListView.separated(
      separatorBuilder: (context, index) => CurrencyListSeparator(),
      itemCount: currenciesWithoutSelected.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () async {
            Logger.print("tapped index: $index");
            if (index == 0 || current.isEmpty) {
              // ignore if already selected currency
              return;
            }
            final manager = Provider.of<Manager>(context, listen: false);
            current = currenciesWithoutSelected[index];
            currenciesWithoutSelected.remove(current);
            currenciesWithoutSelected.insert(0, current);
            manager.changeFiatCurrency(current);
          },
          child: Container(
            key: Key("currencySelect_${currenciesWithoutSelected[index]}"),
            color: index == 0 ? CFColors.fog : CFColors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              child: Text(
                currenciesWithoutSelected[index],
                key: (index == 0)
                    ? Key("selectedCurrencySettingsCurrencyText")
                    : null,
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

class CurrencyListSeparator extends StatelessWidget {
  const CurrencyListSeparator({Key key, this.height = 1.0}) : super(key: key);

  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: CFColors.fog,
    );
  }
}
