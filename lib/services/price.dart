import 'dart:convert';
import 'dart:developer';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:paymint/utilities/logger.dart';

class PriceAPI {
  static Map<String, DateTime> _lastCalled = {};
  static Map<String, Decimal> _price = {};

  static const Duration throttle = Duration(seconds: 60);

  static Future<Decimal> getPrice({String ticker, String baseCurrency}) async {
    String currency = baseCurrency.toLowerCase();

    DateTime now = DateTime.now();

    if (_lastCalled[ticker + baseCurrency] == null ||
        now.difference(_lastCalled[ticker + baseCurrency]) > throttle ||
        _price[ticker + baseCurrency] == null ||
        _price[ticker + baseCurrency] == Decimal.fromInt(-1)) {
      _lastCalled[ticker + baseCurrency] = now;
      log("Attempting to fetch and use a new price api value");
    } else {
      log("Using cached price api value");
      return _price[ticker + baseCurrency] ?? Decimal.fromInt(-1);
    }

    try {
      final binanceResponse = await http.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {'Content-Type': 'application/json'},
      );

      final coinGeckoResponse = await http.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$currency"),
        headers: {'Content-Type': 'application/json'},
      );

      final binanceData = json.decode(binanceResponse.body);
      final Decimal firoBtcPrice = Decimal.tryParse(binanceData["price"]);

      final coinGeckoData = json.decode(coinGeckoResponse.body);
      final Decimal btcUsdPrice =
          Decimal.tryParse(coinGeckoData["bitcoin"][currency].toString());

      if (btcUsdPrice != null && firoBtcPrice != null) {
        final price = firoBtcPrice * btcUsdPrice;
        _price[ticker + baseCurrency] = price;
        return price;
      } else {
        Logger.print(
            "PriceAPI.getPrice($ticker, $currency) failed. Returning a price of -1.");
        return Decimal.fromInt(-1);
      }
    } catch (e) {
      Logger.print(
          "Exception caught in PriceAPI.getPrice($ticker, $currency): $e\nReturning a price of -1.");
      return Decimal.fromInt(-1);
    }
  }
}
