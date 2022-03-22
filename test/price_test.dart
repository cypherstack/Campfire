import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paymint/services/price.dart';

import 'price_test.mocks.dart';

@GenerateMocks([Client])
void main() {
  test("single price fetch", () async {
    final ticker = "FIRO";
    final currency = "USD";

    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async =>
        Response('{"symbol":"${ticker}BTC","price":"0.00001000"}', 200));

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currency.toLowerCase()}"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response('{"bitcoin":{"usd":42000}}', 200));

    final priceAPI = PriceAPI(client);

    final price =
        await priceAPI.getPrice(ticker: ticker, baseCurrency: currency);

    expect(price.toString(), "0.42");

    expect(() => priceAPI.resetCache(), returnsNormally);
  });

  test("cached price fetch", () async {
    final ticker = "FIRO";
    final currency = "USD";

    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async =>
        Response('{"symbol":"${ticker}BTC","price":"0.00001000"}', 200));

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currency.toLowerCase()}"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response('{"bitcoin":{"usd":42000}}', 200));

    final priceAPI = PriceAPI(client);

    await priceAPI.getPrice(ticker: ticker, baseCurrency: currency);

    final cachedPrice =
        await priceAPI.getPrice(ticker: ticker, baseCurrency: currency);

    expect(cachedPrice.toString(), "0.42");

    verify(client.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {'Content-Type': 'application/json'})).called(1);
    verify(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currency.toLowerCase()}"),
        headers: {'Content-Type': 'application/json'})).called(1);

    expect(() => priceAPI.resetCache(), returnsNormally);
  });

  test("response parse failure", () async {
    final ticker = "FIRO";
    final currency = "USD";

    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async =>
        Response('{"symbol":"${ticker}BTC","price":"0.000010rer"}', 200));

    when(client.get(
        Uri.parse(
            "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=${currency.toLowerCase()}"),
        headers: {
          'Content-Type': 'application/json'
        })).thenAnswer((_) async => Response('{"bitcoin":{"USD":42000}}', 200));

    final priceAPI = PriceAPI(client);

    final price =
        await priceAPI.getPrice(ticker: ticker, baseCurrency: currency);

    expect(price.toString(), "-1");

    expect(() => priceAPI.resetCache(), returnsNormally);
  });

  test("no internet available", () async {
    final ticker = "FIRO";
    final currency = "USD";

    final client = MockClient();

    when(client.get(
        Uri.parse(
            "https://api.binance.com/api/v3/ticker/price?symbol=${ticker}BTC"),
        headers: {
          'Content-Type': 'application/json'
        })).thenThrow(SocketException(
        "Failed host lookup: 'api.binance.com' (OS Error: Temporary failure in name resolution, errno = -3)"));

    final priceAPI = PriceAPI(client);

    final price =
        await priceAPI.getPrice(ticker: ticker, baseCurrency: currency);

    expect(price.toString(), "-1");

    expect(() => priceAPI.resetCache(), returnsNormally);
  });
}
